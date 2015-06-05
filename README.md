Poppy software installation
===========================

This tutorial describe how to install a clean poppy embedded linux environment from scratch.

To do that you will need :

 - your poppy main board (odroid U3 or pasberryPi)
 - the associated memmory card
 - a card reader for your computer
 - an ethernet connection to your network (internet and local)


First of all you need to install your linux system. Please refer to your board manual ([odroid U3](http://com.odroid.com/sigong/nf_file_board/nfile_board_view.php?keyword=&tag=ODROID-U3&bid=243) or [raspberryPi](http://www.raspberrypi.org/downloads/)).

Generally you have to download your image plug your memory card into your computer, unmount it and do a binary copy of the image :
 ```bash
$ umount /dev/sdh1 #unmount your memory card
$ sudo ls #This is a patch to avoid any bug into the dd commande...
[sudo] password for yourmachine:
...
$ sudo dd bs=4M if=yourSystem.img | pv | sudo dd of=/dev/sdh # binary copy with progress bar.
...
 ```

Now you have a clean and fresh installation, you can mount your memory card to your board, plug your ethernet connection, and power up.
If you have any wifi or bluetooth USB dongle you can plug it.

Let's start the installation :

 1. Connecting you to the board over ssh.
    ```bash
      $ ssh odroid@odroid.local
      odroid@odroid.local password: "odroid"
      odroid@odroid:~$
    ```

 2. Download and run poppy_setup.sh
    ```bash
      odroid@odroid:~$ curl -L https://raw.githubusercontent.com/poppy-project/poppy_install/master/poppy_setup.sh | sudo bash
    ```
    Do not forget to set the root password "odroid"

 3. You should lost your ssh connection because of the board reboot. This reboot is needed to proceed to the finalisation of the partition resizing. Now your board should installing all the poppy environement. Please do not unpower the board or shut-it down.  
 You can see the instalation process by reconnecting you to your board with your new poppy acount:
```bash
  $ ssh poppy@poppy.local
  poppy@poppy.local password: "poppy"
  poppy@poppy:~$
```
  A process will automatically take you terminal and print the installation output. You can leave it with `ctrl+c`. You can get back this print by reading the install_log file :
```bash
poppy@poppy:~$ tail -f /home/poppy/install_log
...
```
If the last line is :
```bash
System install complete!
Please share your experiences with the community : https://forum.poppy-project.org/
```
The installation is finish, you can restart your Poppy and start to play!
```bash
poppy@poppy:~$ sudo reboot
```
