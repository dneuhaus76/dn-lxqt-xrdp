# dn-lxqt-xrdp
Debian 12 (bookworm based image with lxqt). 
Docker "only" image connect for xrdp (Tested on arm64 raspberry pi 4 and amd64 "docker" vm)

## included
### xrdp
### sound
- pipewire-module-xrdp
### Apps
- chromium (incl. keepassXC add-in)
- keepassXC (preconfigured for chromium)
- thunderbird
- 

example: with sound redirection and current machines user-home into "thinclient_drives" 
```
rdesktop -k de-ch -r sound:local -r disk:"$(hostname)"=/home/${USER} [myserver]
```
