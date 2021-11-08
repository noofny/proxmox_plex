#!/bin/bash


# locale
echo "Setting locale..."
LOCALE_VALUE="en_AU.UTF-8"
echo ">>> locale-gen..."
locale-gen ${LOCALE_VALUE}
cat /etc/default/locale
source /etc/default/locale
echo ">>> update-locale..."
update-locale ${LOCALE_VALUE}
echo ">>> hack /etc/ssh/ssh_config..."
sed -e '/SendEnv/ s/^#*/#/' -i /etc/ssh/ssh_config


echo "Installing dependencies..."
# https://github.com/intel/compute-runtime/releases
# TODO: still getting warnings about these packages
#   ocl-icd-libopencl1
#       (https://forums.plex.tv/t/hdr-tone-mapping-force-software-transcoding/656729)
#   intel-ocloc
#       (https://forums.plex.tv/t/intel-ocloc-not-installed/753466/13)
mkdir /tmp/intel_compute_runtime
cd /tmp/intel_compute_runtime
wget https://github.com/intel/compute-runtime/releases/download/21.44.21506/intel-gmmlib_21.2.1_amd64.deb
wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.8744/intel-igc-core_1.0.8744_amd64.deb
wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.8744/intel-igc-opencl_1.0.8744_amd64.deb
wget https://github.com/intel/compute-runtime/releases/download/21.44.21506/intel-opencl-icd_21.44.21506_amd64.deb
wget https://github.com/intel/compute-runtime/releases/download/21.44.21506/intel-level-zero-gpu_1.2.21506_amd64.deb
wget https://github.com/intel/compute-runtime/releases/download/21.44.21506/ww44.sum
sha256sum -c ww44.sum
dpkg -i *.deb


# install
echo "Installing Plex..."
echo deb https://downloads.plex.tv/repo/deb public main | tee /etc/apt/sources.list.d/plexmediaserver.list
curl https://downloads.plex.tv/plex-keys/PlexSign.key | apt-key add -
apt update && apt install -y plexmediaserver


echo "Setup complete - you can access the console at http://$(hostname -I):32400/web"
