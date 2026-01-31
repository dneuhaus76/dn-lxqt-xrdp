#!/bin/bash
#20_dbus-start.sh


# Verzeichnis für Socket erstellen
# in container init achtung wenn tmpfs - zur laufzeit
mkdir -pv /run/dbus /var/run/dbus
chown -v messagebus:messagebus /run/dbus /var/run/dbus
chmod -v 755 /run/dbus /var/run/dbus


# Eindeutige ID generieren (wichtig für DBus-Funktion)
dbus-uuidgen --ensure


# Machine-ID sicherstellen (Essenziell für D-Bus Kommunikation)
if [ ! -f /etc/machine-id ]; then
    dbus-uuidgen > /var/lib/dbus/machine-id
    ln -sf /var/lib/dbus/machine-id /etc/machine-id
fi


# Start des Daemons im Vordergrund
exec /usr/bin/dbus-daemon --system --nofork --nopidfile


exit 0
