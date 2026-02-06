# dn-lxqt-xrdp
Debian 12 (bookworm based image with lxqt).
Docker "only" image connect for xrdp (tested on arm64 raspberry pi 4 and amd64 "docker" vm)

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
- installed: pipewire-module-xrdp
- need sound-test-command? - "speaker-test -t sine -f 440 -c 2"

### local user
- name: **user** & pw:**user**

## tests
Warning: some of this "features are only working by decreased security"
### copy & paste
- source: Windows rdp client --> VDI container
- - (file copied to desktop) = ok

### "drive/resource" redirection
* source: Windows rdp client --> VDI container = ok
* <img width="696" height="366" alt="image" src="https://github.com/user-attachments/assets/a17f7df9-faf9-457f-9330-6799a2335701" />


## run
### docker command
quick & dirty "fix" for "chromium sandbox mode" **--cap-add=SYS_ADMIN**
```
docker run -d -p 3389:3389 --cap-add=SYS_ADMIN dneuhaus76/dn-lxqt-xrdp:latest
```
### docker compose
*But cap_add and security_opt like this is vulnerable and for debugging only - maybe switch to another browser like firefox and not use features as gvfs...*
```
services:
  vdi:
    build:
      context: .
    image: dneuhaus76/dn-lxqt-xrdp
    container_name: dn-lxqt-xrdp
    shm_size: '2gb'
    restart: always

    volumes:
      - dn-lxqt-xrdp_home:/home

    cap_add:
      - SYS_ADMIN

    devices:
      - "/dev/fuse:/dev/fuse"

    security_opt:
      #- seccomp=./seccomp.json
      - apparmor:unconfined

    ports:
      - "3389:3389"

    networks:
      - dn-lxqt-xrdp

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
