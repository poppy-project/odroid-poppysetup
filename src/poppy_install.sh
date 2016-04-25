#!/usr/bin/env bash
set -x

usage() {
  echo "Usage: $0 [-S, --use-stable-release] CREATURE1 CREATURE2 ..." 1>&2
  exit 1
}

while getopts ":S" opt; do
  case $opt in
    S)
      use_stable_release=1
      ;;
    *)
      usage
      exit 1
  esac
done

shift $((OPTIND-1))

creatures=$@
EXISTING_ONES="poppy-humanoid poppy-torso"

if [ "${creatures}" == "" ]; then
  echo 'ERROR: option "CREATURE" not given. See -h.' >&2
  exit 1
fi

for creature in $creatures
  do
  if ! [[ $EXISTING_ONES =~ $creature ]]; then
    echo "ERROR: creature \"${creature}\" not among possible creatures (choices \"$EXISTING_ONES\")"
    exit 1
  fi
done


install_pyenv() {
  sudo apt-get install -y curl git
  sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm
  sudo apt-get install -y libfreetype6-dev libpng++-dev

  curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  echo "
  export PATH=\"\$HOME/.pyenv/bin:\$PATH\"
  eval \"\$(pyenv init -)\"
  eval \"\$(pyenv virtualenv-init -)\"" >> $HOME/.bashrc
}

install_python() {
  pyenv install -s 2.7.11
  pyenv global 2.7.11
}

install_python_std_packages() {
  # Install Scipy dependancies
  sudo apt-get -y install libblas3gf libc6 libgcc1 libgfortran3 liblapack3gf libstdc++6 build-essential gfortran python-all-dev libatlas-base-dev
  # not sure it is realy needed
  pip install --upgrade pip
  pip install jupyter
  pip install numpy
  pip install scipy
  pip install matplotlib
}

configure_jupyter()
{
    JUPYTER_CONFIG_FILE=$HOME/.jupyter/jupyter_notebook_config.py
    JUPTER_NOTEBOOK_FOLDER=$HOME/notebooks

    mkdir $JUPTER_NOTEBOOK_FOLDER

    jupyter notebook --generate-config

    cat >>$JUPYTER_CONFIG_FILE << EOF
# --- Poppy configuration ---
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '$JUPTER_NOTEBOOK_FOLDER'
# --- Poppy configuration ---
EOF

    python -c """
import os

from jupyter_core.paths import jupyter_data_dir

d = jupyter_data_dir()
if not os.path.exists(d):
    os.makedirs(d)
"""

    pip install https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip --user
}

autostart_jupyter()
{
    sudo sed -i.bkp "/^exit/i #jupyter service\n$HOME/.jupyter/start-daemon &\n" /etc/rc.local

    cat >> $HOME/.jupyter/launch.sh << 'EOF'
export PATH=$HOME/.pyenv/shims/:$PATH
jupyter notebook
EOF

    cat >> $HOME/.jupyter/start-daemon << EOF
#!/bin/bash
su - $(whoami) -c "bash $HOME/.jupyter/launch.sh"
EOF

    chmod +x $HOME/.jupyter/launch.sh $HOME/.jupyter/start-daemon
}

install_poppy_software() {
  if [ -z "$use_stable_release" ]; then
    if [ -z "$POPPY_ROOT" ]; then
      POPPY_ROOT="${HOME}/dev"
    fi

    mkdir -p $POPPY_ROOT
  fi

  for repo in pypot poppy-creature $creatures
  do
    pip install $repo
  done
}

configure_dialout() {
  sudo adduser $USER dialout
}

install_puppet_master() {
    cd || exit
    wget https://github.com/poppy-project/puppet-master/archive/master.zip
    unzip master.zip
    rm master.zip
    mv puppet-master-master puppet-master

    pushd puppet-master
        pip install flask pyyaml requests

        python bootstrap.py poppy $creatures
        install_snap "$(pwd)"
    popd
}

install_snap()
{
    pushd $1
        wget https://github.com/jmoenig/Snap--Build-Your-Own-Blocks/archive/master.zip
        unzip master.zip
        rm master.zip
        mv Snap--Build-Your-Own-Blocks-master snap

        pypot_root=$(python -c "import pypot, os; print(os.path.dirname(pypot.__file__))")
        ln -s $pypot_root/server/snap_projects/pypot-snap-blocks.xml snap/libraries/poppy.xml
        echo -e "poppy.xml\tPoppy robots" >> snap/libraries/LIBRARIES

        for project in $pypot_root/server/snap_projects/*.xml; do
            ln -s $project snap/Examples/

            filename=$(basename "$project")
            echo -e "$filename\tPoppy robots" >> snap/Examples/EXAMPLES
        done

        wget https://github.com/poppy-project/poppy-monitor/archive/master.zip
        unzip master.zip
        rm master.zip
        mv poppy-monitor-master monitor
    popd
}

autostartup_webinterface()
{
    cd || exit

    sudo sed -i.bkp "/^exit/i #puppet-master service\n$HOME/puppet-master/start-pwid &\n" /etc/rc.local


    cat >> $HOME/puppet-master/start-pwid << EOF
#!/bin/bash
su - $(whoami) -c "bash $HOME/puppet-master/launch.sh"
EOF

    cat >> $HOME/puppet-master/launch.sh << 'EOF'
export PATH=$HOME/.pyenv/shims/:$PATH
pushd $HOME/puppet-master
    python bouteillederouge.py 1>&2 2> /tmp/bouteillederouge.log
popd
EOF
    chmod +x $HOME/puppet-master/launch.sh $HOME/puppet-master/start-pwid
}

redirect_port80_webinterface()
{
    cat >> firewall << EOF
#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Flush any existing firewall rules we might have
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Perform the rewriting magic.
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 5000
EOF
    chmod +x firewall
    sudo chown root:root firewall
    sudo mv firewall /etc/network/if-up.d/firewall
}

install_custom_raspiconfig()
{
    wget https://raw.githubusercontent.com/poppy-project/odroid-poppysetup/master/odroid-config.sh -O raspi-config
    chmod +x raspi-config
    sudo chown root:root raspi-config
    sudo mv raspi-config /usr/bin/
}

setup_update()
{
    cd || exit
    wget https://raw.githubusercontent.com/poppy-project/raspoppy/master/poppy-update.sh -O ~/.poppy-update.sh

    cat >> poppy-update << EOF
#!/usr/bin/env python

import os
import yaml

from subprocess import call


with open(os.path.expanduser('~/.poppy_config.yaml')) as f:
    config = yaml.load(f)


with open(config['update']['logfile'], 'w') as f:
    call(['bash', os.path.expanduser('~/.poppy-update.sh'),
          config['update']['url'],
          config['update']['logfile'],
          config['update']['lockfile']], stdout=f, stderr=f)
EOF
    chmod +x poppy-update
    mv poppy-update $HOME/.pyenv/versions/2.7.11/bin/
}

install_opencv() {
    sudo apt-get install -y build-essential cmake pkg-config libgtk2.0-dev libjpeg8-dev libtiff5-dev libjasper-dev libpng12-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libatlas-base-dev gfortran python-dev python-numpy
    wget https://github.com/Itseez/opencv/archive/3.1.0.tar.gz -O opencv.tar.gz
    tar xvfz opencv.tar.gz
    rm opencv.tar.gz
    pushd opencv-3.1.0
        mkdir build
        pushd build
            cmake -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -D PYTHON_EXECUTABLE=/usr/bin/python ..
            make -j4
            sudo make install
            ln -s /usr/local/lib/python2.7/dist-packages/cv2.so $HOME/.pyenv/versions/2.7.11/lib/python2.7/cv2.so
        popd
    popd

}

install_poppy_environment() {
  install_pyenv
  install_python
  install_python_std_packages
  install_poppy_software
  configure_jupyter
  autostart_jupyter
  install_puppet_master
  autostartup_webinterface
  redirect_port80_webinterface
  install_custom_raspiconfig
  setup_update
  install_opencv

  echo "Your system will now reboot..."
  sudo reboot
}

install_poppy_environment
