#!/bin/sh
# /opt/displaylink/udev.sh — DisplayLink hotplug bootstrap (Gentoo build)
#
# start_service/stop_service detect the running init system at runtime,
# so a single script works on both systemd and OpenRC hosts.

start_service()
{
  if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
    systemctl start --no-block dlm.service
  elif command -v rc-service >/dev/null 2>&1; then
    rc-service --ifexists dlm start
  fi
}

stop_service()
{
  if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
    systemctl stop dlm.service
  elif command -v rc-service >/dev/null 2>&1; then
    rc-service --ifexists dlm stop
  fi
}

get_displaylink_dev_count()
{
   cat /sys/bus/usb/devices/*/idVendor 2>/dev/null | grep 17e9 | wc -l
}

get_displaylink_symlink_count()
{
  root=$1
  if [ ! -d "$root/displaylink/by-id" ]; then
    echo "0"
    return
  fi
  for f in $(find "$root/displaylink/by-id" -type l -exec realpath {} \; 2> /dev/null); do
    test -c "$f" && echo "$f";
  done | wc -l
}

start_displaylink()
{
  if [ "$(get_displaylink_dev_count)" != "0" ]; then
    start_service
  fi
}

stop_displaylink()
{
  root=$1
  if [ "$(get_displaylink_symlink_count "$root")" = "0" ]; then
    stop_service
  fi
}

create_displaylink_symlink()
{
  root=$1
  device_id=$2
  devnode=$3
  mkdir -p "$root/displaylink/by-id"
  ln -sf "$devnode" "$root/displaylink/by-id/$device_id"
}

unlink_displaylink_symlink()
{
   root=$1
   devname=$2
   for f in "$root"/displaylink/by-id/*; do
     if [ ! -e "$f" ] || ([ -L "$f" ] && [ "$f" -ef "$devname" ]); then
       unlink "$f"
     fi
   done
   (cd "$root"; rmdir -p --ignore-fail-on-non-empty displaylink/by-id 2>/dev/null)
}

disable_u1_u2()
{
    echo 0 > "/sys$1/../port/usb3_lpm_permit" 2>/dev/null || true
}

main()
{
  action=$1
  root=$2
  devpath=$3
  devnode=$5

  if [ "$action" = "add" ]; then
    device_id=$4
    create_displaylink_symlink "$root" "$device_id" "$devnode"
    start_displaylink
    disable_u1_u2 "$devpath"
  elif [ "$action" = "remove" ]; then
    devname=$3
    unlink_displaylink_symlink "$root" "$devname"
    stop_displaylink "$root"
  elif [ "$action" = "START" ]; then
    start_displaylink
  fi
}

main "$@"
