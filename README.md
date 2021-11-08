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

## Inspiration

- [Install Plex or Jellyfin with Hardware Acceleration inside a LXC container on Proxmox](https://ashu.io/blog/media-server-lxc-proxmox/)
- [Best Practices for running Plex on Proxmox?](https://www.reddit.com/r/Proxmox/comments/f8bdv5/best_practices_for_running_plex_on_proxmox/)
