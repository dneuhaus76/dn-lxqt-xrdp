#!/bin/sh
# xrdp X session start script (c) 2015, 2017, 2021 mirabilos
# published under The MirOS Licence

# Rely on /etc/pam.d/xrdp-sesman using pam_env to load both
# /etc/environment and /etc/default/locale to initialise the
# locale and the user environment properly.

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

# Locale
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE LC_ALL LC_TIME LC_MONETARY LC_PAPER LC_MEASUREMENT LC_NUMERIC
fi


#config is in Xsession
exec dbus-run-session -- /etc/X11/Xsession

