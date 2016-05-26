# Shrink the ISO

## Remove some unused stuff to save space

### For U3

```bash
sudo apt-get remove -y chromium-browser libreoffice* kodi firefox valgrind gnome-user-guide faenza-icon-theme openjdk-7-jre-headless llvm-3.4-dev sunpinyin-data fonts-unfonts-core

sudo apt-get autoremove -y

sudo rm -rf /home/poppy/dev/opencv-3.1.0/
sudo rm -rf /home/poppy/.cache/
```

### For XU4

```bash
sudo apt-get remove -y chromium-browser firefox valgrind gnome-user-guide faenza-icon-theme openjdk-7-jre-headless thunderbird texlive* sunpinyin-data fonts-nanum fonts-takao-mincho fonts-unfonts-core llvm-3.4-dev

sudo apt-get autoremove -y

sudo rm -rf /home/poppy/dev/opencv-3.1.0/
sudo rm -rf /home/poppy/.cache/
```

## Shrink the ISO using another linux
```bash
sudo fdisk -l
sudo e2fsck -fy /dev/sda2
sudo resize2fs /dev/sda2 5100M -f
sudo parted /dev/sda resizepart 2 5500M
```

## Expand the partition on first boot

* Restart the Odroid on your shrinked ISO

```bash
ssh odroid@poppy.local

sudo su -

resize_p2() {
    DATE=`date +%Y.%m.%d-%H.%M`
    # this takes in consideration /dev/mmcblk0p2 as the rootfs!
    rsflog=/root/resize-$DATE-log.txt
    echo -e "\e[33mSaving partitioning log to $rsflog\e[0m"
    sleep 4

    p2_start=`fdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $2}'`
    p2_finish=$((`fdisk -l /dev/mmcblk0 | grep total | grep sectors | awk '{printf $8}'` - 1024))
    echo $p2_start
    echo $p2_finish
    fdisk /dev/mmcblk0 <<EOF &>> $rsflog
p
d
2
n
p
2
$p2_start
$p2_finish
p
w
EOF

    cat <<\EOF > /etc/init.d/resize2fs_once
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO
. /lib/lsb/init-functions
case "$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs /dev/mmcblk0p2 &&
    rm /etc/init.d/resize2fs_once &&
    update-rc.d resize2fs_once remove &&
    log_end_msg $?
    ;;
  *)
    echo "Usage: $0 start" >&2
    exit 3
    ;;
esac
EOF

  chmod +x /etc/init.d/resize2fs_once
  update-rc.d resize2fs_once defaults
  REBOOT=1

  return 0
}

resize_p2
halt
```

## Save the ISO as an .img file
```bash
sudo dd bs=1m count=5200 if=/dev/rdisk2 of=poppy-humanoid-u3-$(date +%F).img
```
