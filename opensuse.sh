#!/usr/bin/env bash

# make sure installer script isnt run as root
if [ "$(id -u)" = "0" ]
then
  echo -e "\nThis script must not be run as root\n" 1>&2
  exit 1

  # debian usage warning
  if [[ $(lsb_release -is) != 'Debian' ]]
  then
    echo -e "\nThis script was designed for Debian-based distributions. Press [Enter] to proceed. Otherwise, press Ctrl+c to exit installer.\n";
    read;
  fi
fi
# check for chomper dir, in case script is run multiple times
if [ -d ~/chomper ]
then
  echo -e "\nChomper directory detected. Remove the directory with '$ rm -rf ~/chomper' to use this script.\n";
  exit 1;
else
  echo -e "\nInstalling dependencies...\n";
  sudo zypper -n install --type pattern devel_basis
  sudo zypper -n install git build-essential curl zlib-devel libbz2-devel sqlite3-devel readline-devel ncurses-devel libopenssl-devel gdbm-devel python-pip mozilla-nss-tools screen;
fi

cd ~/ && git clone https://github.com/aniketpanjwani/chomper.git;
cd chomper;

if [ ":$PATH:" != *":/home/$USER/chomper/bin"* ]
then
  echo 'export PATH=$PATH:/home/$USER/chomper/bin' >> ~/.bashrc
  echo 'export PATH=$PATH:/home/$USER/chomper/bin' >> ~/.bash_profile
  echo -e "\nAdded Chomper to PATH.\n"
else
  echo -e "\nChomper is already on PATH.\n"
fi

# Install pyenv
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo  -e '\nif command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
echo  -e '\nif command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bash_profile
source ~/.bashrc
source ~/.bash_profile
exec $SHELL -l
pyenv install 3.6.4

# Install pipenv and virtual environment
sudo -H python -m pip install -U pipenv # Install pipenv

pipenv --venv  || pipenv --two # Check if virtualenv exists

pipenv install --dev --python 3.6.4 # Install packages

# Install certificates
screen -d -m pipenv run mitmdump
sleep 2
pkill -f mitmdump # Generate certificates
openssl x509 -outform der -in /home/$USER/.mitmproxy/mitmproxy-ca.pem -out /home/$USER/.mitmproxy/mitmproxy-ca.crt
sudo cp /home/$USER/.mitmproxy/mitmproxy-ca.crt /usr/lib/ca-certificates/mitmproxy-ca.crt # Install root certificates
sudo update-ca-certificates
sudo sh ./chomper/certs.sh # Make browsers recognize root certificates

# Enable ip forwarding
sudo sysctl -w net.ipv4.ip_forward=1 # Enable ipv4 forwarding
sudo sysctl -w net.ipv6.conf.all.forwarding=1 # Enable ipv6 forwarding
sudo sysctl -p # Lock in new ip forwarding settings.
