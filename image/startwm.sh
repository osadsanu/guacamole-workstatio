#!/bin/sh
# Session script run by xrdp-sesman for every RDP login: start an XFCE desktop.
# Everything the session prints lands in ~/.xsession-errors for debugging.
exec >"${HOME}/.xsession-errors" 2>&1
echo "[startwm] $(date) DISPLAY=${DISPLAY} user=$(id -un)"

if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
# Proxy / cluster settings written by the entrypoint for GUI sessions.
if [ -r /etc/profile.d/workstation-env.sh ]; then
  . /etc/profile.d/workstation-env.sh
fi

# sesman passes a session bus address / runtime dir that do not exist here;
# give the session its own private runtime dir and let dbus-launch create the bus.
unset DBUS_SESSION_BUS_ADDRESS
XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
mkdir -p "${XDG_RUNTIME_DIR}" && chmod 0700 "${XDG_RUNTIME_DIR}"
export XDG_RUNTIME_DIR
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export DESKTOP_SESSION=xfce
# Software rendering only: xorgxrdp has no GPU/GLX.
export LIBGL_ALWAYS_SOFTWARE=1

exec dbus-launch --exit-with-session startxfce4
