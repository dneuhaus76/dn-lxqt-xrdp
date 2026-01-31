#!/bin/bash
#./script.sh -m docker

set -e

#args
while getopts "m:" opt; do
  case $opt in
    m) mode="$OPTARG" ;;
    *) echo "Invalid option" ;;
  esac
done
echo "Mode: ${mode}"


#vars
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR

export ARCH=$(dpkg --print-architecture)
export PRODUCTNAME="$(dmidecode -s system-product-name)"
export DEBIAN_FRONTEND="noninteractive"
#export TZ="${TZ:-Europe/Zurich}"
export USRNAME='user'
export USRPW='$6$0Dx/oWyy0cXyShrh$NOOVS7.zG..eYOHsgo41NrCpdoquCFIQi.yYajs1PiUbz.ny1o1xoYpp/rIJeOfws4G1qUqqCjw4fW65P7ofC.'
 
# variablen aus file
if [ -f "${SCRIPT_DIR}/environment" ]; then
	. "${SCRIPT_DIR}/environment"
fi
echo "$(env | grep -iv 'LS_COLORS' | sort)"


if [[ "${mode,,}" == "docker" ]]; then
	echo "(docker) - nehme unnötige Sachen weg"
	# Entfernt unnötige Power-Management-Links aus dem LXQt-Menü
	rm -fv /usr/share/applications/lxqt-hibernate.desktop
	rm -fv /usr/share/applications/lxqt-shutdown.desktop
	rm -fv /usr/share/applications/lxqt-reboot.desktop
	rm -fv /usr/share/applications/lxqt-suspend.desktop
	rm -fv /usr/share/applications/lxqt-leave.desktop
	rm -fv /usr/share/applications/lxqt-lockscreen.desktop
	rm -fv /usr/share/applications/lxqt-config-monitor.desktop
	rm -fv /usr/share/applications/lxqt-config-brightness.desktop
	rm -fv /etc/xdg/autostart/lxqt-xscreensaver-autostart.desktop
fi


# import config, installation sicherstellen 
apt-get update
apt-get install -fy
dpkg --configure -a


#set reconfiguration
cat <<EOT | debconf-set-selections
locales locales/default_environment_locale      select  ${SYSLANG}
locales locales/locales_to_be_generated multiselect     ${ADDLANG} UTF-8, ${SYSLANG} UTF-8
tzdata  tzdata/Zones/Etc        select  UTC
tzdata  tzdata/Zones/${TZ1}     select  ${TZ2}
keyboard-configuration  keyboard-configuration/modelcode        string  pc105
keyboard-configuration  keyboard-configuration/variant  select  ${VARIANT}
keyboard-configuration  keyboard-configuration/xkb-keymap       select  ${XKB}
nslcd   nslcd/ldap-uris string  ${LDAPURI}
nslcd   nslcd/ldap-base string  ${LDAPBASE}
nslcd   nslcd/ldap-starttls     boolean false
nslcd   nslcd/ldap-auth-type    select  none 
libnss-ldapd    libnss-ldapd/clean_nsswitch     boolean true
libnss-ldapd    libnss-ldapd/nsswitch   multiselect     passwd, group, shadow
EOT

cat <<EOT >/etc/locale.gen
${SYSLANG} UTF-8
${ADDLANG} UTF-8
EOT
dpkg-reconfigure locales

if ! [ -z "${TZ}" ]; then
 echo "[+] set timezone: ${TZ}"
 dpkg-reconfigure tzdata
 ln -snfv /usr/share/zoneinfo/${TZ} /etc/localtime
fi

if ! [ -z "${XKB}" ]; then
 echo "[+] set keyboard: ${XKB}"
 dpkg-reconfigure keyboard-configuration
fi

dpkg-reconfigure hicolor-icon-theme

#locales set detailed winth addlang
if [ -z "${ADDLANG}" ]; then
 echo "[+] set addlang to syslang: ${SYSLANG}"
 export ADDLANG="${SYSLANG}"
fi
cat <<EOT >/etc/default/locale 
LANG="${SYSLANG}"
LANGUAGE="${SYSLANG}:en"
LC_MESSAGES="${SYSLANG}"
LC_NAME="${SYSLANG}"
LC_COLLATE="${ADDLANG}"
LC_MEASUREMENT="${ADDLANG}"
LC_MONETARY="${ADDLANG}"
LC_NUMERIC="${ADDLANG}"
LC_PAPER="${ADDLANG}"
LC_TIME="${ADDLANG}"
LC_ADDRESS="${ADDLANG}"
LC_CTYPE="${ADDLANG}"
LC_IDENTIFICATION="${ADDLANG}"
LC_TELEPHONE="${ADDLANG}"
EOT


# users & groups
if ! [ -z "${USRNAME}" ]; then
 echo "[+] add user: ${USRNAME}"
 useradd -m -s /bin/bash -c 'sudo user' -p "${USRPW}" ${USRNAME}
 usermod -aG sudo,audio,adm,render,video ${USRNAME}
 sleep 1
fi


# my login config no varialbe translation
file=/etc/bash.bashrc
if ! grep -Fq "\$USER (\$LANG)" "$file"; then
cat <<'EOT' >>$file 
echo; echo "$USER ($LANG) on $HOSTNAME"; hostname -I; id
ls -l /etc/localtime | awk '{print $NF}'
EOT
fi


#nslcd für ldap
if ! [ -z "${LDAPURI}" ]; then
echo "[+] ldapsettings for ${LDAPURI}"
dpkg-reconfigure nslcd
dpkg-reconfigure libnss-ldapd
sed -i "/^uri /c\uri ${LDAPURI}" /etc/nslcd.conf
sed -i "/^base /c\base ${LDAPBASE}" /etc/nslcd.conf
fi


# Datei wird im container als skel kopiert
#file="/usr/lib/chromium/native-messaging-hosts/org.keepassxc.keepassxc_browser.json"
#if [ -f "$file" ]; then
#	chmod -v 644 "$file"
#fi


# Dateien ausführbar machen
find /usr/local/bin -type f -exec chmod +x {} +


# Icon cache - refresh
gtk-update-icon-cache /usr/share/icons/hicolor


# X11 Sockets Verzeichnisse initial und erstellen
#mkdir -pv /tmp/.X11-unix
#chmod -v 1777 /tmp/.X11-unix


# Bereinigung und sich selbst löschen
rm -fv "$0" "/tmp/debconf.conf" "environment"


exit 0
