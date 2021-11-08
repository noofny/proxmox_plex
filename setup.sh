#!/bin/bash -e


# functions
function error() {
    echo -e "\e[91m[ERROR] $1\e[39m"
}
function warn() {
    echo -e "\e[93m[WARNING] $1\e[39m"
}
function info() {
    echo -e "\e[36m[INFO] $1\e[39m"
}
function cleanup() {
    popd >/dev/null
    rm -rf $TEMP_FOLDER_PATH
}


TEMP_FOLDER_PATH=$(mktemp -d)
pushd $TEMP_FOLDER_PATH >/dev/null


# prompts/args
DEFAULT_HOSTNAME='plex'
DEFAULT_PASSWORD='plexadmin'
DEFAULT_IPV4_CIDR='192.168.0.10/24'
DEFAULT_IPV4_GW='192.168.0.1'
read -p "Enter a hostname (${DEFAULT_HOSTNAME}) : " HOSTNAME
read -s -p "Enter a password (${DEFAULT_PASSWORD}) : " HOSTPASS
echo -e "\n"
read -p "Enter an IPv4 CIDR (${DEFAULT_IPV4_CIDR}) : " HOST_IP4_CIDR
read -p "Enter an IPv4 Gateway (${DEFAULT_IPV4_GW}) : " HOST_IP4_GATEWAY
HOSTNAME="${HOSTNAME:-${DEFAULT_HOSTNAME}}"
HOSTPASS="${HOSTPASS:-${DEFAULT_PASSWORD}}"
HOST_IP4_CIDR="${HOST_IP4_CIDR:-${DEFAULT_IPV4_CIDR}}"
HOST_IP4_GATEWAY="${HOST_IP4_GATEWAY:-${DEFAULT_IPV4_GW}}"
export HOST_IP4_CIDR=${HOST_IP4_CIDR}
CONTAINER_OS_TYPE='ubuntu'
CONTAINER_OS_VERSION='20.04'
CONTAINER_OS_STRING="${CONTAINER_OS_TYPE}-${CONTAINER_OS_VERSION}"
info "Using OS: ${CONTAINER_OS_STRING}"
CONTAINER_ARCH=$(dpkg --print-architecture)
mapfile -t TEMPLATES < <(pveam available -section system | sed -n "s/.*\($CONTAINER_OS_STRING.*\)/\1/p" | sort -t - -k 2 -V)
TEMPLATE="${TEMPLATES[-1]}"
TEMPLATE_STRING="local:vztmpl/${TEMPLATE}"
info "Using template: ${TEMPLATE_STRING}"


# storage location
STORAGE_LIST=( $(pvesm status -content rootdir | awk 'NR>1 {print $1}') )
if [ ${#STORAGE_LIST[@]} -eq 0 ]; then
    warn "'Container' needs to be selected for at least one storage location."
    die "Unable to detect valid storage location."
elif [ ${#STORAGE_LIST[@]} -eq 1 ]; then
    STORAGE=${STORAGE_LIST[0]}
else
    info "More than one storage locations detected."
    PS3=$"Which storage location would you like to use? "
    select storage_item in "${STORAGE_LIST[@]}"; do
        if [[ " ${STORAGE_LIST[*]} " =~ ${storage_item} ]]; then
            STORAGE=$storage_item
            break
        fi
        echo -en "\e[1A\e[K\e[1A"
    done
fi
info "Using '$STORAGE' for storage location."


# Get the next guest VM/LXC ID
CONTAINER_ID=$(pvesh get /cluster/nextid)
info "Container ID is $CONTAINER_ID."


# Create the container
# TODO: specify root disk size!
info "Creating Privileged LXC container..."
pct create "${CONTAINER_ID}" "${TEMPLATE_STRING}" \
    -arch "${CONTAINER_ARCH}" \
    -cores 4 \
    -memory 2048 \
    -swap 2048 \
    -onboot 1 \
    -features nesting=1 \
    -hostname "${HOSTNAME}" \
    -net0 name=eth0,bridge=vmbr0,gw=${HOST_IP4_GATEWAY},ip=${HOST_IP4_CIDR} \
    -ostype "${CONTAINER_OS_TYPE}" \
    -password ${HOSTPASS} \
    -storage "${STORAGE}"


# Configure GPU passthrough
info "Configuring passthrough..."
ls -l /dev/dri
CONTAINER_CONFIG_FILE="/etc/pve/lxc/${CONTAINER_ID}.conf"
echo "lxc.cgroup.devices.allow: c 226:* rwm" >> ${CONTAINER_CONFIG_FILE}
echo "lxc.mount.entry: /dev/dri/card0 dev/dri/card0 none bind,optional,create=file" >> ${CONTAINER_CONFIG_FILE}
echo "lxc.mount.entry: /dev/dri/renderD128 dev/dri/renderD128 none bind,optional,create=file" >> ${CONTAINER_CONFIG_FILE}


# Start container
info "Starting LXC container..."
pct start "${CONTAINER_ID}"
sleep 5


# Setup OS
info "Fetching setup script..."
wget -qL https://raw.githubusercontent.com/noofny/proxmox_plex/master/setup_os.sh
info "Executing script..."
cat ./setup_os.sh
pct push "${CONTAINER_ID}" ./setup_os.sh /setup_os.sh -perms 755
pct exec "${CONTAINER_ID}" -- bash -c "/setup_os.sh"
pct reboot "${CONTAINER_ID}"


# Setup plex
info "Fetching setup script..."
wget -qL https://raw.githubusercontent.com/noofny/proxmox_plex/master/setup_plex.sh
info "Executing script..."
cat ./setup_plex.sh
pct push "${CONTAINER_ID}" ./setup_plex.sh /setup_plex.sh -perms 755
pct exec "${CONTAINER_ID}" -- bash -c "/setup_plex.sh"


# Done - reboot!
rm -rf ${TEMP_FOLDER_PATH}
info "Container and app setup - container will restart!"
pct reboot "${CONTAINER_ID}"