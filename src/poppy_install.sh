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
EXISTING_ONES="poppy-humanoid poppy-ergo-jr poppy-torso"

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
  pyenv install -s 2.7.9
  pyenv global 2.7.9
}

install_python_std_packages() {
  # Install Scipy dependancies
  sudo apt-get install libblas3gf libc6 libgcc1 libgfortran3 liblapack3gf libstdc++6 build-essential gfortran python-all-dev libatlas-base-dev
  pip install numpy
  pip install scipy
  pip install matplotlib
  pip install ipython[all]
}

install_notebook_startup() {
    curl -L https://raw.githubusercontent.com/poppy-project/poppy-installer/master/install-deps/install-notebook.sh | sudo bash
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
    cd $POPPY_ROOT

    if [ ! -z "$use_stable_release" ]; then
      pip install $repo
    else
      git clone https://github.com/poppy-project/$repo.git

      cd $repo
      if [[ $repo == poppy-* ]]; then
        cd software
      fi

      python setup.py develop

    fi
  done
}

configure_dialout() {
  sudo adduser $USER dialout
}

install_poppy_environment() {
  install_pyenv
  install_python
  install_python_std_packages
  install_poppy_software
  install_notebook_startup

  echo "Please now reboot your system"
}

install_poppy_environment