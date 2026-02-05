#FROM dneuhaus76/bookworm AS base
FROM debian:bookworm-slim AS base

ENV DEBIAN_FRONTEND=noninteractive

ARG XWM=xfwm4

RUN apt-get update && apt install -y --no-install-recommends \
    nano sudo locales zip openssh-client ca-certificates supervisor \
    dbus dbus-user-session dbus-x11 \
    xrdp xorgxrdp xorg xauth \
    ${XWM} x11-xserver-utils fonts-dejavu-core && \
    # config
    adduser xrdp ssl-cert && \
    # abschluss
    apt-get purge -y xscreensaver && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*


# Fenster-Manager Priorisierung
RUN update-alternatives --install /usr/bin/x-window-manager x-window-manager /usr/bin/${XWM} 50 && \
    update-alternatives --set x-window-manager /usr/bin/${XWM}


# --- STAGE 2: Desktop
FROM base AS desktop-build


ARG XSESSION_PKGS='lxqt-session lxqt-panel lxqt-config pcmanfm-qt qterminal lxqt-archiver lxqt-themes oxygen-icon-theme qt5-style-plugin-cleanlooks'
ARG BROWSER="chromium"
ARG GVFS_PKGS='gvfs gvfs-fuse gvfs-backends'
#ARG GVFS_PKGS


RUN apt-get update && apt install -y --no-install-recommends \
    libnss-ldapd libpam-ldapd ldap-utils \
    ${XSESSION_PKGS} ${GVFS_PKGS} \
    fuse3 sshfs xdg-user-dirs \
    featherpad qpdfview screengrab lximage-qt qps ${BROWSER} thunderbird keepassxc && \
    # Entferne unnötige Dienste
    apt-get purge -y xscreensaver xterm pulseaudio && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*


#Sound
RUN apt-get update && apt-get install -y --no-install-recommends \
    pipewire pipewire-pulse pipewire-audio-client-libraries wireplumber alsa-utils pulseaudio-utils pavucontrol-qt && \
    apt-get purge -y pulseaudio && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*


# --- STAGE: MODULE-BUILD
FROM desktop-build AS module-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git pkg-config autotools-dev autoconf automake libtool make gcc libpipewire-0.3-dev libspa-0.2-dev

WORKDIR /build

# Repository klonen und Vorgänge laut Readme ausführen
RUN git clone --branch devel https://github.com/neutrinolabs/pipewire-module-xrdp.git && \
    cd pipewire-module-xrdp && \
    ./bootstrap && \
    ./configure && \
    make && \
    # Wir erstellen das Verzeichnis sicherheitshalber vorher
    mkdir -p /tmp/xrdp-audio-out && \
    make install DESTDIR=/tmp/xrdp-audio-out
    

# --- STAGE 3: Final
FROM desktop-build AS final

#geht nur automatisch mit buildx
ARG TARGETPLATFORM
ARG TARGETARCH
ARG VERSION="12.13"
ARG SYSLANG="en_US.UTF-8"


# Metadaten (OCI Standards) - Nur letzte Stage
# Autoren- und Basis-Informationen
LABEL org.opencontainers.image.authors="Daniel Neuhaus <kueder1@gmx.net>" \
      org.opencontainers.image.vendor="dneuhaus76" \
      org.opencontainers.image.source="https://github.com/dneuhaus76/debian-lxqt-xrdp" \
      org.opencontainers.image.licenses="MIT"

# Projekt-Details
LABEL org.opencontainers.image.title="Debian 12 VDI (LXQt + XRDP)" \
      org.opencontainers.image.description="Debian LXQt Desktop VDI mit xfwm4 und xrdp" \
      org.opencontainers.image.version="${VERSION}"

# Technische Spezifikationen (Meta-Daten)
LABEL de.dneuhaus.base-distro="Debian 12 (Bookworm)" \
      de.dneuhaus.vdi.desktop="LXQt" \
      de.dneuhaus.vdi.wm="xfwm4" \
      de.dneuhaus.vdi.remote="xrdp" \
      de.dneuhaus.vdi.lang="${SYSLANG}" \
      de.dneuhaus.vdi.arch="${TARGETARCH}"

# Kopiere die gebauten Module aus der vorherigen Stage
COPY --from=module-builder /tmp/xrdp-audio-out/. /


# Verzeichnisstruktur sicherstellen
#COPY ./containerfiles/etc/. /etc/
#COPY ./containerfiles/usr/. /usr/
#COPY ./containerfiles/tmp/. /tmp/
ADD ./containerfiles.tar /tmp/staging/
COPY ./install.sh /tmp/


# Init-Skripte & User-Setup
# Führe mein Script für Einstellungen aus
RUN truncate -s 0 /etc/machine-id && \
    /usr/bin/bash /tmp/install.sh -m docker


EXPOSE 3389


CMD ["/usr/bin/supervisord", "-n"]

