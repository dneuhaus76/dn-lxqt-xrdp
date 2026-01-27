# dn-lxqt-xrdp
Debian 12 (bookworm based image with lxqt).
Docker "only" image connect for xrdp (Tested on arm64 raspberry pi 4 and amd64 "docker" vm)

## included
### supervisor (startup manager)
### xrdp (for connection)
### xfwm4 & lxqt
### Apps
- chromium (incl. keepassXC add-in)
- keepassXC (preconfigured for chromium)
- thunderbird
- featherpad,lximage,screengrab,qpdfview,qterminal,qps
### sound
- pipewire-module-xrdp
### local user
- name: user & pw:user

example: with sound redirection and current machines user-home into "thinclient_drives" 
```
rdesktop -k de-ch -r sound:local -r disk:"$(hostname)"=/home/${USER} [myserver]
```
