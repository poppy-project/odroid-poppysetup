#!/bin/sh

do_change_hostname() {
   oldhostname=$(hostname)
   echo $1 > /etc/hostname
   sed -i "s/$oldhostname/$1/g" /etc/hosts
   /usr/sbin/service avahi-daemon restart
}

# Everything else needs to be run as root
if [ $(id -u) -ne 0 ]; then
  printf "Script must be run as root.\n"
  exit 1
fi


for i in $*
do
  case $i in
  --change-hostname)
    INTERACTIVE=False
    do_change_hostname $2
    shift
    exit $?
    ;;
  *)
    # unknown option
    ;;
  esac
done
