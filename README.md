# Poppy software installation for odroid board

This tutorial describe how to install a clean poppy embedded linux environment from scratch.

To do that you will need :

 - your poppy main board (odroid U3 or XU4)
 - the associated memory card
 - a card reader for your computer
 - an ethernet connection to your network (internet and local)


First of all you need to install your linux system. Please refer to your board manual ([odroid U3](http://com.odroid.com/sigong/nf_file_board/nfile_board_view.php?keyword=&tag=ODROID-U3&bid=243) or [raspberryPi](http://www.raspberrypi.org/downloads/)).

Generally you have to download your image plug your memory card into your computer, unmount it and do a binary copy of the image (replace /dev/sdh by your device):
 ```bash
umount /dev/sdh1 #unmount your memory card
sudo dd bs=4M if=yourSystem.img of=/dev/sdh # binary copy
```

Note: if you are running OSX or any BSD based system use (replace /dev/sdh by your device): 
```
sudo dd bs=4m if=yourSystem.img of=/dev/sdh
```

**For more informations on how to burn a system image, look at the installation chapter of the [Poppy documentation](http://docs.poppy-project.org/en/installation/burn-an-image-file.html#write-an-image-to-the-sd-card).**

Now you have a clean and fresh installation, you can mount your memory card to your board, plug your ethernet connection, and power up.
If you have any wifi or bluetooth USB dongle you can plug it.

Let's start the installation :

 1. Connecting you to the board over ssh. `ssh odroid@odroid.local` password=odroid

 2. Download and run poppy_setup.sh
```bash
wget https://raw.githubusercontent.com/poppy-project/odroid-poppysetup/master/poppy_setup.sh -O poppy_setup.sh && sudo bash poppy_setup.sh poppy-humanoid
```
    Do not forget to set the root password "odroid"

 3. You should lose your ssh connection because of the board reboot. This reboot is needed to proceed to the finalisation of the partition resizing. Now your board should installing all the poppy environment. Please do not unpower the board or shut-it down.  
 You can see the installation process by reconnecting you to your board with your new poppy account `ssh poppy@poppy.local` password=poppy.

  A process will automatically take you terminal and print the installation output. You can leave it with `ctrl+c`. You can get back this print by reading the install_log file :
```bash
tail -f /home/poppy/install_log
```
If the last line is :
```bash
System install complete!
Please share your experiences with the community : https://forum.poppy-project.org/
```
The installation is finish, you can restart your Poppy and start to play!
```bash
sudo reboot
```
