# Plex on ProxMox

<p align="center">
    <img height="200" alt="Plex Logo" src="img/logo_plex.png">
    <img height="200" alt="ProxMox Logo" src="img/logo_proxmox.png">
</p>

Create a [ProxMox](https://www.proxmox.com/en/) LXC container running Ubuntu and install [Plex.](https://www.plex.tv/)

Tested on ProxMox v7 and Plex 4.6

## Usage

SSH to your ProxMox server as a privileged user and run...

```shell
bash -c "$(wget --no-cache -qLO - https://raw.githubusercontent.com/noofny/proxmox_plex/master/setup.sh)"
```

## External/USB Media

You can use this pretty erasilly, once you have [attached and mounted}(https://www.techrepublic.com/article/how-to-properly-automount-a-drive-in-ubuntu-linux/) it on the host. Say your Plex container ID is `1234` and you mounted the drive on your ProxMox host at `/media/my_media`...
- SSH to ProxMox and run `pct set 1234 -mp0 /media/my_media,mp=/mnt/my_media,backup=0`
- SSH to your Plex box and you should see this mounted at `/mnt/my_media`

## Inspiration

- [Install Plex or Jellyfin with Hardware Acceleration inside a LXC container on Proxmox](https://ashu.io/blog/media-server-lxc-proxmox/)
- [Best Practices for running Plex on Proxmox?](https://www.reddit.com/r/Proxmox/comments/f8bdv5/best_practices_for_running_plex_on_proxmox/)
