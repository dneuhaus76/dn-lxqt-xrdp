# dn-lxqt-xrdp 
[docker hub](https://hub.docker.com/r/dneuhaus76/dn-lxqt-xrdp)

Debian 12 (bookworm based image with lxqt).
Docker "only" image connect for xrdp (tested on arm64 raspberry pi 4 and amd64 "docker" vm)
Why rdp: I think RDP is not bad and the common denominator (If migrating from other OS where RDP is widespread) - So you have no "Big Bang" pressure if something is not working as desired

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/3b3d761a-76a2-4ce6-8711-a6a1cf8275f9" />

## included
### chromium in docker (take notice):
I like chomium but --> maybe with another browser...
https://medium.com/code-and-coffee/running-chromium-in-docker-without-selling-your-soul-433e591802f2
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
- need sound-test-command? - **"speaker-test -t sine -f 440 -c 2"**

### local user
- name: **user**
- pw: **user**

## tests
*Warning: some of this "features" are only working by decreased security*
### copy & paste
- source: Windows rdp client --> VDI container
  - copy file to desktop = ok
  - Windows Clipboard to a text file = ok
- source: linux rdesktop --> VDI container 
  - copy file to desktop = no (but you can use the redirection)

### "drive/resource" redirection
* source: Windows rdp client --> VDI container = ok

  <img width="50%" height="50%" alt="image" src="https://github.com/user-attachments/assets/a17f7df9-faf9-457f-9330-6799a2335701" />
  
* source: linux rdesktop --> VDI container = ok

  <img width="50%" height="50%" alt="image" src="https://github.com/user-attachments/assets/0a8cb58a-11a1-4e89-92fe-eeaaaf0ae247" />

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

## A UseCase - Network-Diagram
This is an example only (but a working example in my lab)...
Here you could either or connect through _(I prefer tunneled RDP, but cuacamole is top for administration work)_
* cuacamole: https (clientless) --> RDP --> VDI
* ssh tunnel: rdpclient --> VDI

```mermaid
graph TB
   subgraph WAN [Internet / Public Zone]
       User((User<br/>mstsc via tunnel<br/>id_ed25519))
       WebBrowser(User<br/>Webbrowser<br/>Clientless)
   end


   subgraph TargetGateway [Gateway Layer]
       forward_ssh[Internet-Gateway<br/>Port FW: xxx22]
       forward_https[Internet-Gateway<br/>Port FW: xxx80]
   end


   subgraph Docker_Host [Raspberry Pi Node]
       subgraph DMZ_Net [Management Network]
           Bastion["<b>dn-bastion-ssh</b><br/>2FA (key & passphrase)<br/>Hardened OpenSSH<br/>(ssh Tunnel)"]
       end
       subgraph DMZ_HTTPS_Net [Management Network]
           Guacamole["<b>dn-guacamole</b><br/>2FA</br>Clientless Access<br/>(HTTPS Stream)"]
       end
       subgraph Service_Net [Internal Service Mesh]
           RDP_VDI["<b>dn-lxqt-xrdp</b><br/>Debian 12 VDI<br/>(XFWM4 + LXQt)"]
           Auth["<b>dn-srv-net</b><br/>Identity & Net Core<br/>(LDAP/DNS/DHCP)"]
       end
   end


   %% Connection Logic
   User -- "SSH Tunnel via xxx22" --> forward_ssh
   WebBrowser -- "https" --> forward_https
   forward_ssh -- "Forward" --> Bastion
   forward_https -- "Forward" --> Guacamole
   Bastion -- "L-Forward 33890:3389" --> RDP_VDI
   RDP_VDI -- "Auth Request" --> Auth
   Guacamole -- "RDP-over-HTTP" --> RDP_VDI


   %% Styling
   style Bastion fill:#f96,stroke:#333,stroke-width:2px
   style Guacamole fill:#f96,stroke:#333,stroke-width:2px
   style RDP_VDI fill:#bbf,stroke:#333,stroke-width:2px
```
