#! /bin/bash

if [ `whoami` != "root" ];
then
    echo "You must run the app as root:"
    echo "sudo bash $0"
    exit 0
fi

# Wait internet

while true
do
    wget -q --tries=10 --timeout=20 -O - http://google.com > /dev/null
    if [[ $? -eq 0 ]]; then
        break
    fi
done

echo 'Starting the Poppy environement installation' >> /home/poppy/install_log
sed -i /install_log/d /home/poppy/.bashrc
echo tail -f /home/poppy/install_log >> /home/poppy/.bashrc

# allow poppy to use sudo without password
chmod +w /etc/sudoers
echo "poppy ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod -w /etc/sudoers
usermod --pass='*' root # don't need root password any more
export HOME=/home/poppy

# Update needed apps.

# Poppy creatures installer
creature=`cat /home/odroid/src/creature`

su - poppy -c "curl -L https://raw.githubusercontent.com/poppy-project/odroid-poppysetup/master/src/poppy_install.sh | bash -s $creature" >> /home/poppy/install_log


# Remove instalation at startup
sed -i /install_log/d /home/poppy/.bashrc
crontab -r

echo 'System install complete!' >> /home/poppy/install_log
echo "Please share your experiences with the community : https://forum.poppy-project.org/"  >> /home/poppy/install_log
