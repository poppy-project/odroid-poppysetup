# Poppy software installation for odroid board

This tutorial describe how to install a clean poppy embedded linux environment from scratch.

To do that you will need :

 - your poppy main board (odroid U3 or XU4)
 - the associated memory card
 - a card reader for your computer
 - an ethernet connection to your network (internet and local)


These boards come with a working Ubuntu base image on the MMC you can use the install scripts on it.
In the case you have not a fresh installation you have download and burn default system images:
* [Ubuntu 14.04 for Odroid U3](http://odroid.com/dokuwiki/doku.php?id=en:u3_release_linux_ubuntu)
* [Ubuntu 14.04 for Odroid XU3/XU4](http://odroid.in/ubuntu_14.04lts/ubuntu-14.04.1lts-lubuntu-odroid-xu3-20150212.img.xz)

To burn it on the MMC/SD-card, look at the [startup section of the Poppy Documentation](http://docs.poppy-project.org/en/installation/burn-an-image-file.html#write-an-image-to-the-sd-card).

Now you have a clean and fresh installation, you can mount your memory card to your board, plug your ethernet connection, and power up.

Login to the board in SSH: `ssh odroid@odroid.local`, password=odroid.

> **Info** If you are using Windows, you have no native SSH client ; you have to download and install [putty](http://www.putty.org/) or [mobaxterm](http://mobaxterm.mobatek.net/) to use SSH.

Be sure that your board is connected to the Internet, download and run poppy_setup.sh (replace 'poppy-humanoid' below with poppy-torso' if you want to install a Poppy Torso robot):
```
wget https://raw.githubusercontent.com/poppy-project/odroid-poppysetup/master/poppy_setup.sh -O poppy_setup.sh
sudo bash poppy_setup.sh poppy-humanoid
```
You should lose your ssh connection because of the board reboot. This reboot is needed to proceed to the finalisation of the partition resizing. Now your board should installing all the poppy environment. **Please do not unpower the board or shut-it down.**

You can see the installation process by reconnecting you to your board with your new poppy account: `ssh poppy@poppy.local` password=poppy. 
**Because of the compilation of heavy Python packages (Scipy, Numpy) it can take 30 to 45 minutes to complete.**

A process will automatically take you terminal and print the installation output. You can leave it with `ctrl+c`. You can get back this print by reading the install_log file:
```
tail -f /home/poppy/install_log
```
Be patient...

At the end of the installation, your board will reboot again. You can look at the log `tail -f /home/poppy/install_log`, if everything ended well, last lines should be:

```
System install complete!
Please share your experiences with the community : https://forum.poppy-project.org/
```

> **Note:** If you are not sure of what going up, you can see if the install process is running with: `ps up $(pgrep -f 'poppy_launcher.sh')`

The hostname, default user and password will be all set to "poppy" (`ssh poppy@poppy.local` password=poppy).
You can test your installation with the web interface in your web browser http://poppy.local.


