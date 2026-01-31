#!/bin/bash

set -e

#args
while getopts "m:" opt; do
  case $opt in
    m) mode="$OPTARG" ;;
    *) echo "Invalid option" ;;
  esac
done
echo "Mode: ${mode}"

if [[ "${mode,,}" == "docker" ]]; then
	echo "mode: - ${mode}"
fi

### CHECKS ###
if [[ $EUID -ne 0 ]]; then
  echo "Bitte als root ausführen!"
  exit 1
fi

#vars
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR

export ARCH=$(dpkg --print-architecture)
export PRODUCTNAME="$(dmidecode -s system-product-name)"
export DEBIAN_FRONTEND="noninteractive"

export MIRROR="http://ftp.ch.debian.org/debian/"
export DIST="${DIST:-bookworm}"
export ROOTFS="${DIST}-${ARCH}"
export TARFILE="./${ROOTFS}.tar.gz"

# variablen aus file
if [ -f "./environment" ]; then
	source ./environment
fi

cd /tmp
echo $PWD
echo "Start: $0"
echo "arch: ${ARCH}"
echo "productname: ${PRODUCTNAME}"

function createBootstrapImage() {
	# disable ipv6 during this installation
	sysctl -w net.ipv6.conf.all.disable_ipv6=1
	sysctl -w net.ipv6.conf.default.disable_ipv6=1

	echo "[+] Cleanup mounts..."
	umount -lf $ROOTFS/{dev,proc,sys} 2>/dev/null || true
	DEBOOTSTRAP="debootstrap --arch=${ARCH} --variant=minbase --components=main,contrib,non-free-firmware $DIST ${DIST}-${ARCH} ${MIRROR}"
	
	apt-get update
	apt-get install -yqq debian-archive-keyring debian-keyring debootstrap>/dev/null
	echo "trying to: $DEBOOTSTRAP"
	if ! [ -d "${DIST}-${ARCH}" ]; then
 	sudo $DEBOOTSTRAP >/dev/null
 	if [ $? -eq 0 ]; then 
  	echo "...OK"
 	else 
  	echo "...[Error] es ist ein Fehler aufgetreten"
 	fi
	else
 	echo "Ordner existiert bereits"
	fi
}

function mountRootfs() {
	echo "[+] Mounting pseudo filesystems..."
	mount -v --bind /dev  "$ROOTFS/dev"
	mount -v --bind /proc "$ROOTFS/proc"
	mount -v --bind /sys  "$ROOTFS/sys"
}

function provisionImage() {
echo "[+] chroot provisioning..."
chroot "$ROOTFS" /bin/bash <<'EOF'
set -e
#echo "root:root" | chpasswd

apt update
apt-get install -y \
  firmware-linux firmware-linux-free firmware-linux-nonfree firmware-misc-nonfree \
		amd64-microcode intel-microcode firmware-atheros firmware-iwlwifi firmware-realtek firmware-amd-graphics \
		firmware-intel-sound firmware-sof-signed firmware-brcm80211 bluez-firmware fwupd \
  nano sudo locales console-setup zip openssh-client ca-certificates debconf-utils iputils-ping \
  dbus dbus-user-session \
  xrdp xorgxrdp xorg xauth \
  xserver-xorg-core xserver-xorg-input-all xserver-xorg-video-all network-manager-gnome lightdm slick-greeter desktop-base \
  xfwm4 x11-xserver-utils fonts-dejavu-core \
  lxqt-session lxqt-panel lxqt-config lxqt-openssh-askpass lxqt-powermanagement pcmanfm-qt qterminal lxqt-archiver lxqt-themes oxygen-icon-theme qt5-style-plugin-cleanlooks \
  featherpad qpdfview screengrab lximage-qt qps chromium thunderbird keepassxc \
  pipewire pipewire-pulse pipewire-audio-client-libraries wireplumber alsa-utils pavucontrol-qt
apt-get purge -y connman xscreensaver pulseaudio
apt-get autoremove -y && apt-get clean

adduser xrdp ssl-cert

# machine-id leeren (wichtig!)
truncate -s 0 /etc/machine-id

EOF
}

function createArchive() {
	echo "[+] Tarball erzeugen..."
	if ! [ -f "${TARFILE}" ]; then
		tar --numeric-owner -czpf "${TARFILE}" -C "${ROOTFS}" .
	fi
	echo "[!] Fertig: $TARFILE ist im /tmp"
}

function umountRootfs() {
	echo "[+] Cleanup mounts..."
	umount -v $ROOTFS/{dev,proc,sys}
}

#main
createBootstrapImage
mountRootfs
provisionImage
umountRootfs
createArchive


#finish
read
exit 0
#lightdm-settings
