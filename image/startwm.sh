#!/bin/sh
# Session script run by xrdp-sesman for every RDP login: start an XFCE desktop.
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
# Proxy / cluster settings written by the entrypoint for GUI sessions.
if [ -r /etc/profile.d/workstation-env.sh ]; then
  . /etc/profile.d/workstation-env.sh
fi
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
exec dbus-launch --exit-with-session startxfce4
