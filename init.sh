#! /bin/bash

# get ssh public key
read -p "Please enter Public SSH Key: " PUB
echo ""
# get git deets
read -p "Please enter First and Last name: " GUSER
echo ""
read -p "Please enter your GitHub email address: " GEMAIL
echo ""

#Setup Hostname
read -p "Please choose hostname: " HOSTNAME
hostnamectl set-hostname $HOSTNAME
echo ""
IP=$(curl -s6 icanhazip.com)
echo "$IP   $HOSTNAME" >> /etc/hosts
IP=$(curl -s4 icanhazip.com)
echo "$IP   $HOSTNAME" >> /etc/hosts
echo "Hostname set as $HOSTNAME"
echo ""
#Set timezone  TODO:  Figure out how to have this be set automagically
timedatectl set-timezone 'America/New_York'
echo "Time Zone set to America/New_York" && date
echo ""
#Setup user account
read -p "Please choose username: " USER
useradd $USER && passwd $USER
usermod -aG wheel $USER

#Create folder for ssh key and get key and add to ssh folder
mkdir -p /home/$USER/.ssh && chmod -R 700 /home/$USER/.ssh
touch /home/$USER/.ssh/authorized_keys && chmod 644 /home/$USER/.ssh/authorized_keys
echo "$PUB" > /home/$USER/.ssh/authorized_keys
chown -R $USER:$USER /home/$USER/.ssh

# disable password and root logins over ssh
sed -i -e "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
systemctl restart sshd

# add /usr/local/bin to secure_path in sudoers file
sed -i -e "s/usr\/bin$/usr\/bin:\/usr\/local\/bin/" /etc/sudoers

echo "Installing fail2ban"  #*********************************
sleep 2
#install and configure fail2ban
yum -y install fail2ban

systemctl start fail2ban
systemctl enable fail2ban

cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local

fail2ban-client status

echo "ssh key added logins configured"
echo "Your jawn is now somewhat secure"
echo ""

#Update Centos 7  ***************************************
yum -y update
yum -y install epel-release

echo "Installing Tools" #*********************************
sleep 2
yum -y install git
yum -y install lynx
yum -y install wget
yum -y install nmap
yum -y install psmisc
yum -y install telnet
yum -y install vim-enhanced

git config --global user.name "$GUSER"
git config --global user.email "$GEMAIL"

echo "Installing Python3.7" #*********************************
yum groupinstall -y "development tools"
yum install -y \
  libffi-devel \
  zlib-devel \
  bzip2-devel \
  openssl-devel \
  ncurses-devel \
  sqlite-devel \
  readline-devel \
  tk-devel \
  gdbm-devel \
  db4-devel \
  libpcap-devel \
  xz-devel \
  expat-devel \
  postgresql-devel

cd /usr/src
wget http://python.org/ftp/python/3.7.2/Python-3.7.2.tar.xz
tar xf Python-3.7.2.tar.xz
cd Python-3.7.2
./configure --enable-optimizations
make altinstall
pip3.7 install --upgrade pip


echo " Configure some bash stuff" #*********************************
curl https://raw.githubusercontent.com/linuxacademy/content-intro-to-python-development/master/helpers/bashrc -o /home/$USER/.bashrc
echo 'alias pyth="python3.7"' >> /home/$USER/.bash_profile
. /home/$USER/.bash_profile

echo " Configure some vim stuff" #*********************************
curl https://raw.githubusercontent.com/linuxacademy/content-intro-to-python-development/master/helpers/vimrc -o /home/$USER/.vimrc
echo "All dunzo!  Please log out and log back in with the username: $USER"
exit
