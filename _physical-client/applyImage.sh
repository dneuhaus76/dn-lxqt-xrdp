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
#network check
ping -c2 -4 www.google.ch >/dev/null
if [ $? -ne 0 ]; then
  echo; echo "is network connected..."
  read
fi

#vars
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR

export ARCH=$(dpkg --print-architecture)
export PRODUCTNAME="$(dmidecode -s system-product-name)"
export DEBIAN_FRONTEND="noninteractive"
export COMPUTERNAME="dn-lxqt"
export RAM_TOTAL_GB=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
export DISK=""
export ROOT="/mnt"
export TARFILE="./bookworm-${ARCH}.tar.gz"
export PART=""
# variablen aus file
if [ -f "./environment" ]; then
	source ./environment
fi

echo;[ -d /sys/firmware/efi ] && echo "EFI boot on HDD" || echo "Legacy boot on HDD"

echo; lsblk -o NAME,SIZE,MOUNTPOINT | grep -v 'loop'; echo
echo "Enter Device name (/dev/x)"
read -r DISK; DISK="${DISK:-/dev/mmcblk0}"

# Check if the device is an eMMC or a hard disk
export PART=$DISK
if [[ $DISK == *nvme* || $DISK == *mmcblk* ]]; then
    PART="${DISK}p"
fi

function mountRoot() {
	echo "[+] Mounting pseudo filesystems..."
	mount -v --bind /dev  "${ROOT}/dev"
	mount -v --bind /proc "${ROOT}/proc"
	mount -v --bind /sys  "${ROOT}/sys"
	mount -t efivarfs efivarfs "${ROOT}/sys/firmware/efi/efivars"
}

function umountRoot() {
	echo "[+] Cleanup mounts..."
	#umount -v $ROOT/{dev,proc,sys}
	umount -Rv "${PART}" || true
}

function createDiskSchema() {
	echo "[!] WARNUNG: ${DISK} wird geloescht!"
	read -rp "Weiter? (yes): " CONFIRM
	[[ "$CONFIRM" == "yes" ]] || exit 1

	umountRoot
	umount -Rl ${ROOT} >/dev/null 2>&1 || true
    
    # Cleanup bootsector (vorsichtig, beabsichtigt)
    dd if=/dev/zero of="${DISK}" bs=512 count=1 >/dev/null 2>&1 || true
    
	echo "[+] Partitionierung..."
	parted -s "${DISK}" \
  	mklabel gpt \
  	mkpart ESP fat32 1MiB 513MiB \
  	set 1 esp on \
  	mkpart ROOT ext4 513MiB 100%
	
	mkfs.fat -F32 "${PART}1"
	if [ $? -ne 0 ]; then echo "...mkfs.vfat Fehler"; fi
	mkfs.ext4 -F "${PART}2"
	if [ $? -ne 0 ]; then echo "...mkfs.ext4 Fehler"; fi
	
	mount -v "${PART}2" "${ROOT}"
	if ! $(mountpoint -q ${ROOT}) ; then echo "${ROOT} nicht gemountet"; read; fi
	mkdir -p "${ROOT}/boot/efi"
	mount -v "${PART}1" "${ROOT}/boot/efi"
    if ! mountpoint -q ${ROOT}/boot/efi ; then echo "${ROOT}/boot/efi nicht gemountet"; read; fi
}

function extractTarfile() {
	#extractTarfile ./lxqtdebian.tar true
	local TARFILE="'"$1"'"
	local CMD="tar -v -xzf "${TARFILE}" -C "${ROOT}""
	if [ "$2" == true ]; then
		CMD="tar --numeric-owner -xzpf "${TARFILE}" -C "${ROOT}""
	fi
	if ! [ -f "$1" ]; then 
		echo "file nicht gefunden: $1"
		read
	else 
		echo "[+] ${TARFILE} extrahieren..."
		echo "    ${CMD}"
		eval $CMD
	fi
}

function runInstall() {
# Schreibe fstab (überschreiben, nicht anhängen) mit UUID
echo "[+] schreibe fstab..."
mkdir -p ${ROOT}/etc
fs_efi_uuid=$(blkid -s UUID -o value ${PART}1)
fs_root_uuid=$(blkid -s UUID -o value ${PART}2)
cat <<EOT > ${ROOT}/etc/fstab
UUID=${fs_efi_uuid} /boot/efi vfat umask=0077 0 1
UUID=${fs_root_uuid} / ext4 defaults 0 1
EOT

if [ "$RAM_TOTAL_GB" -lt 8 ]; then
	#Create swapFile
	fallocate -l 3G ${ROOT}/swapfile
	chmod 600 ${ROOT}/swapfile
	mkswap ${ROOT}/swapfile
	echo "/swapfile  none  swap  sw  0  0">>${ROOT}/etc/fstab
fi

echo "[+] chroot setup..."
chroot "${ROOT}" /bin/bash <<EOF
set -e

# grub and kernel 
apt-get install -yq grub-efi-amd64-signed shim-signed grub-common linux-image-amd64
#grub-install
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --recheck
update-initramfs -u -k all
update-grub
echo "$(efibootmgr  -v)"
EOF
}

function runCustomisation() {
	echo "[+] prepare and chroot setup..."
	local EXECFILE="$1";EXECFILE=${EXECFILE:-/tmp/install.sh}
	echo "    checkfile: ${ROOT}/${EXECFILE}"
	if ! [ -f "${ROOT}/${EXECFILE}" ]; then
		echo "file not found: ${EXECFILE}"
		#return
	fi
	if [ -f "./environment" ]; then
		cp -v "./environment" /tmp/
	fi
	chroot "${ROOT}" /bin/bash "${EXECFILE}"
}

#main
createDiskSchema
extractTarfile "${TARFILE}" true
# runInstall = basis
mountRoot
runInstall

# customisation
extractTarfile "./lxqtdebian.tar.gz"
runCustomisation /tmp/install.sh

# PerMachineCustomisation
extractTarfile "./${PRODUCTNAME}.tar.gz"
#runCustomisation /tmp/install.sh
#finish
umountRoot
echo "[!] Installation abgeschlossen – Taste fuer poweroff"
#read
poweroff -fp
exit 0

# Optional: Zusätzlich den Fallback-Pfad bespielen für maximale Kompatibilität
#grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --removable
#mkdir -p /boot/efi/EFI/BOOT
#cp /usr/lib/shim/shimx64.efi.signed /boot/efi/EFI/BOOT/BOOTX64.EFI
#cp /usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed /boot/efi/EFI/BOOT/grubx64.efi

