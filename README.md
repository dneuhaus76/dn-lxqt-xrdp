# dn-lxqt-xrdp
Debian 12 (bookworm based image with lxqt).
Docker "only" image connect for xrdp (Tested on arm64 raspberry pi 4 and amd64 "docker" vm)

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/3b3d761a-76a2-4ce6-8711-a6a1cf8275f9" />

## included
### supervisor (startup manager)
### xrdp (for connection)
### xfwm4 & lxqt
### Apps
- chromium (incl. keepassXC add-in)
  - configured with json-policy-file
- keepassXC (preconfigured for chromium)
- thunderbird
- featherpad,lximage,screengrab,qpdfview,qterminal,qps
### sound
- pipewire-module-xrdp
### local user
- name: user & pw:user

## run
### docker command
quick & dirty "fix" for "chromium sandbox mode" & sshfs empty file content **--cap-add=SYS_ADMIN**
```
docker run -d -p 3389:3389 --cap-add=SYS_ADMIN dneuhaus76/dn-lxqt-xrdp:latest
```
### docker compose
```
services:
  lxqt:
    image: dneuhaus76/dn-lxqt-xrdp
    container_name: dn-lxqt-xrdp
    shm_size: '2gb'
    #restart: always

    volumes:
      - dn-lxqt-xrdp_home:/home

    ports:
      - "3389:3389"

    networks:
      - dn-lxqt-xrdp

    cap_add:
      - SYS_ADMIN  #if sshfs-emty

    devices:
      - "/dev/dri:/dev/dri" #GPU-Acceleration (V3D)
      - "/dev/fuse:/dev/fuse" #if sshfs-emty

    security_opt:
      - apparmor:unconfined #remove if all works as expected

volumes:
  dn-lxqt-xrdp_home:
    name: "dn-lxqt-xrdp_home"

networks:
  dn-lxqt-xrdp:
    driver: bridge
    name: "dn-lxqt-xrdp"
```

## connect from an rdp-client
example: with sound redirection and current machines user-home into "thinclient_drives" 
```
rdesktop -k de-ch -r sound:local -r disk:"$(hostname)"=/home/${USER} [myserver]
```

### chromium in docker:
Or maybe with another browser like firefox...
https://medium.com/code-and-coffee/running-chromium-in-docker-without-selling-your-soul-433e591802f2