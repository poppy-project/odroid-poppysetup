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


install_pyenv() 
{
  sudo apt-get install -y curl git
  sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm
  sudo apt-get install -y libfreetype6-dev libpng++-dev

  curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash

  
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  # Remove all occurences to pyenv in ~/.bashrc
  sed -i /pyenv/d $HOME/.bashrc
  
  # If a .bash_profile is present, .bashrc will not be loaded
  rm $HOME/.bash_profile
  
  echo "
  export PATH=\"\$HOME/.pyenv/bin:\$PATH\"
  eval \"\$(pyenv init -)\"
  eval \"\$(pyenv virtualenv-init -)\"" >> $HOME/.bashrc
}

install_python() 
{
  pyenv install -s 2.7.11
  pyenv global 2.7.11
}

install_python_std_packages() 
{
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

    mkdir -p $JUPTER_NOTEBOOK_FOLDER

    yes | jupyter notebook --generate-config

    cat >>$JUPYTER_CONFIG_FILE << EOF
# --- Poppy configuration ---
c.NotebookApp.ip = '*'
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '$JUPTER_NOTEBOOK_FOLDER'
c.NotebookApp.tornado_settings = { 'headers': { 'Content-Security-Policy': "frame-ancestors 'self' http://* " } }
c.NotebookApp.allow_origin = '*'
c.NotebookApp.extra_static_paths = ["static/custom/custom.js"]
# --- Poppy configuration ---
EOF

  JUPYTER_CUSTOM_JS_FILE=$HOME/.jupyter/custom/custom.js
  mkdir -p "$HOME/.jupyter/custom"
  cat > "$JUPYTER_CUSTOM_JS_FILE" << EOF
/* Allow new tab to be openned in an iframe */
define(['base/js/namespace'], function(Jupyter){
  Jupyter._target = '_self';
})
EOF

    python -c """
import os

from jupyter_core.paths import jupyter_data_dir

d = jupyter_data_dir()
if not os.path.exists(d):
    os.makedirs(d)
"""

    pip install https://github.com/ipython-contrib/IPython-notebook-extensions/archive/master.zip --user
    jupyter nbextension enable --py widgetsnbextension
}

autostart_jupyter()
{
    sudo sed -i.bkp "/^exit/i #jupyter service\n$HOME/.jupyter/start-daemon &\n" /etc/rc.local

    cat > $HOME/.jupyter/launch.sh << 'EOF'
export PATH=$HOME/.pyenv/shims/:$PATH
jupyter notebook
EOF

    cat > $HOME/.jupyter/start-daemon << EOF
#!/bin/bash
su - $(whoami) -c "bash $HOME/.jupyter/launch.sh"
EOF

    chmod +x $HOME/.jupyter/launch.sh $HOME/.jupyter/start-daemon
}

populate_notebooks()
{
  pushd $HOME/notebooks

      if [ "$creatures" == "poppy-humanoid" ]; then
          curl -o Demo_Poppy_Humanoid.ipynb https://raw.githubusercontent.com/poppy-project/poppy-humanoid/master/software/samples/notebooks/Demo%20Interface.ipynb
          curl -o "Discover your Poppy Humanoid.ipynb" https://raw.githubusercontent.com/poppy-project/poppy-humanoid/master/software/samples/notebooks/Discover%20your%20Poppy%20Humanoid.ipynb
          curl -o "Record, save and play moves on Poppy Humanoid.ipynb" https://raw.githubusercontent.com/poppy-project/poppy-humanoid/master/software/samples/notebooks/Record%2C%20Save%20and%20Play%20Moves%20on%20Poppy%20Humanoid.ipynb

          mkdir -p image
          pushd image
            wget https://raw.githubusercontent.com/poppy-project/poppy-humanoid/master/software/samples/notebooks/image/poppy_humanoid.jpg -O poppy_humanoid.jpg
            wget https://raw.githubusercontent.com/poppy-project/poppy-humanoid/master/software/samples/notebooks/image/poppy_humanoid_motors.png -O poppy_humanoid_motors.png
          popd
      fi
      if [ "$creatures" == "poppy-torso" ]; then
          curl -o "Discover your Poppy Torso.ipynb" https://raw.githubusercontent.com/poppy-project/poppy-torso/master/software/samples/notebooks/Discover%20your%20Poppy%20Torso.ipynb
          curl -o "Record, save and play moves on Poppy Torso.ipynb" https://raw.githubusercontent.com/poppy-project/poppy-torso/master/software/samples/notebooks/Record%2C%20Save%20and%20Play%20Moves%20on%20Poppy%20Torso.ipynb
          
          mkdir -p images
          pushd images
            wget https://raw.githubusercontent.com/poppy-project/poppy-torso/master/software/samples/notebooks/images/poppy_torso.jpg -O poppy_torso.jpg
            wget https://raw.githubusercontent.com/poppy-project/poppy-torso/master/software/samples/notebooks/images/poppy_torso_motors.png -O poppy_torso_motors.png
          popd
      fi
      if [ "$creatures" == "poppy-ergo-jr" ]; then
          curl -o Quickstart_ergo.ipynb https://raw.githubusercontent.com/poppy-project/pypot/master/samples/notebooks/QuickStart%20playing%20with%20a%20PoppyErgo.ipynb 
      fi

      # Download community notebooks
      wget https://github.com/poppy-project/community-notebooks/archive/master.zip -O master.zip
      unzip master.zip
      mv community-notebooks-master community-notebooks
      rm master.zip

      # Copy the documentation pdf
      wget https://www.gitbook.com/download/pdf/book/poppy-project/poppy-docs?lang=en -O documentation.pdf

      ln -s $POPPY_ROOT poppy_src
  popd
}

autostart_zeroconf_poppy_publisher()
{
  sudo sed -i.bkp "/^exit/i #Zeroconf Poppy service\navahi-publish -s $HOSTNAME _poppy_robot._tcp 9 http://poppy-project.org &\n" /etc/rc.local
}
install_poppy_software() 
{
  if [ -z "$use_stable_release" ]; then
    if [ -z "$POPPY_ROOT" ]; then
      POPPY_ROOT="${HOME}/dev"
    fi

    mkdir -p $POPPY_ROOT
  fi

  for repo in pypot $creatures
  do
    pip install $repo
  done

  # Symlink poppy python package to allow more easily to users to view and modify the code
  for repo in pypot $creatures ; do
    # Replace - to _ (I don't like regex)
    module=`ipython -c 'str = "'$repo'" ; print str.replace("-","_")'`

    module_path=`ipython -c 'import '$module', os; print os.path.dirname('$module'.__file__)'`
    ln -s "$module_path" "$POPPY_ROOT"
  done
}

configure_dialout() 
{
  sudo adduser $USER dialout
}

install_puppet_master() 
{
    pushd "$POPPY_ROOT"
        wget https://github.com/poppy-project/puppet-master/archive/master.zip
        unzip master.zip
        rm master.zip
        mv puppet-master-master puppet-master

        pushd puppet-master
            pip install flask pyyaml requests

            python bootstrap.py poppy $creatures --board "Odroid"
            install_snap "$(pwd)"
        popd
    popd
}

install_snap()
{
    pushd $1
        wget https://github.com/jmoenig/Snap--Build-Your-Own-Blocks/archive/master.zip -O master.zip
        unzip master.zip
        rm master.zip
        mv Snap--Build-Your-Own-Blocks-master snap

        pypot_root=$(python -c "import pypot, os; print(os.path.dirname(pypot.__file__))")
        ln -s $pypot_root/server/snap_projects/pypot-snap-blocks.xml snap/libraries/poppy.xml
        echo -e "poppy.xml\tPoppy robots" >> snap/libraries/LIBRARIES

        # Delete snap default examples
        rm snap/Examples/EXAMPLES
        
        # Link pypot Snap projets to Snap! Example folder
        for project in $pypot_root/server/snap_projects/*.xml; do
            ln -s $project snap/Examples/

            filename=$(basename "$project")
            echo -e "$filename\t$filename" >> snap/Examples/EXAMPLES
        done

        wget https://github.com/poppy-project/poppy-monitor/archive/master.zip -O master.zip
        unzip master.zip
        rm master.zip
        mv poppy-monitor-master monitor
    popd
}

autostartup_webinterface()
{
    cd || exit

    sudo sed -i.bkp "/^exit/i #puppet-master service\n$POPPY_ROOT/puppet-master/start-pwid &\n" /etc/rc.local

    cat > $POPPY_ROOT/puppet-master/start-pwid << EOF
#!/bin/bash
su - $(whoami) -c "bash $POPPY_ROOT/puppet-master/launch.sh"
EOF

    cat > $POPPY_ROOT/puppet-master/launch.sh << 'EOF'
export PATH=$HOME/.pyenv/shims/:$PATH
pushd $HOME/dev/puppet-master
    python bouteillederouge.py 1>&2 2> /tmp/bouteillederouge.log
popd
EOF
    chmod +x $POPPY_ROOT/puppet-master/launch.sh $POPPY_ROOT/puppet-master/start-pwid
}

redirect_port80_webinterface()
{
    cat > firewall << EOF
#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Flush any existing firewall rules we might have
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Perform the rewriting magic.
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 2280
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

install_opencv() 
{

    # Get out if opencv is already installed
    if $(python -c "import cv2" &> /dev/null); then
        echo "opencv is already installed"
        return
    fi

    pushd $POPPY_ROOT
        sudo apt-get install -y build-essential cmake pkg-config libgtk2.0-dev libjpeg8-dev libtiff5-dev libjasper-dev libpng12-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libatlas-base-dev gfortran python-dev python-numpy
        wget https://github.com/Itseez/opencv/archive/3.1.0.tar.gz -O opencv.tar.gz
        tar xvfz opencv.tar.gz
        rm opencv.tar.gz
        pushd opencv-3.1.0
            mkdir -p build
            pushd build
                cmake -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -D PYTHON_EXECUTABLE=/usr/bin/python ..
                make -j4
                sudo make install
                ln -s /usr/local/lib/python2.7/dist-packages/cv2.so $HOME/.pyenv/versions/2.7.11/lib/python2.7/cv2.so
            popd
        popd
    popd
}

install_git_lfs()
{
    set -e
    # Get out if git-lfs is already installed
    if $(git-lfs &> /dev/null); then
        echo "opencv is already installed"
        return
    fi

    GIT_LFS_BUILD=$HOME/.bin
    # Install go 1.6 for ARMv6 (works also on ARMv7 & ARMv8)
    mkdir -p "$GIT_LFS_BUILD/go"
    pushd "$GIT_LFS_BUILD/go"
        wget https://storage.googleapis.com/golang/go1.6.2.linux-armv6l.tar.gz -O go.tar.gz
        sudo tar -C /usr/local -xzf go.tar.gz
        rm go.tar.gz
        export PATH=$PATH:/usr/local/go/bin
        export GOPATH=$PWD
        echo "PATH=$PATH:/usr/local/go/bin" >> $HOME/.bashrc
        echo "GOPATH=$PWD" >> $HOME/.bashrc
    
        # Download and compile git-lfs
        mkdir -p src/github.com/github
        pushd src/github.com/github
            git clone https://github.com/github/git-lfs
            pushd git-lfs
              script/bootstrap
              sudo cp bin/git-lfs /usr/bin/
            popd
        popd
    popd
    hash -r 
    git lfs install
    set +e
}

set_logo()
{
    wget https://raw.githubusercontent.com/poppy-project/raspoppy/master/poppy_logo -O $HOME/.poppy_logo
    # Remove old occurences of poppy_logo in .bashrc
    sed -i /poppy_logo/d $HOME/.bashrc
    echo cat $HOME/.poppy_logo >> $HOME/.bashrc
}

install_poppy_environment() 
{
  install_pyenv
  install_python
  install_python_std_packages
  install_poppy_software
  configure_jupyter
  populate_notebooks
  autostart_jupyter
  autostart_zeroconf_poppy_publisher
  install_puppet_master
  autostartup_webinterface
  redirect_port80_webinterface
  install_custom_raspiconfig
  setup_update
  install_opencv
  install_git_lfs
  set_logo

  echo "Your system will now reboot..."
  sudo reboot
}

install_poppy_environment
