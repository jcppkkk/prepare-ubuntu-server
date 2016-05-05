#!/bin/bash
# curl -sL http://git.io/uinit | bash
set -xe

if [ "$UINIT_SCRIPT" != "yes" ]; then
  if [ -f "$0" ]; then
    cp "$0" /tmp/uinit
  else
    curl -sL bit.ly/prep-ubuntu > /tmp/uinit
  fi
  sudo UINIT_SCRIPT=yes bash /tmp/uinit
  exit
fi

export DEBIAN_FRONTEND=noninteractive

grep -q "^#includedir.*/etc/sudoers.d" /etc/sudoers || echo "#includedir /etc/sudoers.d" >> /etc/sudoers
( umask 226 && echo "${SUDO_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/50set convert-meta _${SUDO_USER}_sh )

grep -q 'EDITOR=vim' ~/.bashrc || echo 'EDITOR=vim' >> ~/.bashrc

# Update source list to local mirror

if [ -e /etc/lsb-release ]; then
source /etc/lsb-release
SITE=http://free.nchc.org.tw/ubuntu/  
echo "# full list `date --rfc-3339=seconds`
deb $SITE $DISTRIB_CODENAME main restricted universe multiverse
deb $SITE $DISTRIB_CODENAME-security main restricted universe multiverse
deb $SITE $DISTRIB_CODENAME-updates main restricted universe multiverse
deb $SITE $DISTRIB_CODENAME-backports main restricted universe multiverse
deb-src $SITE $DISTRIB_CODENAME main restricted universe multiverse
deb-src $SITE $DISTRIB_CODENAME-security main restricted universe multiverse
deb-src $SITE $DISTRIB_CODENAME-updates main restricted universe multiverse
deb-src $SITE $DISTRIB_CODENAME-backports main restricted universe multiverse
"| tee /etc/apt/sources.list;
fi

apt-get -yq update
(sudo apt-get autoremove -y)
(sudo apt-get install -y aptitude)
(sudo aptitude -y safe-upgrade)
(sudo aptitude install -y unattended-upgrades ntp git etckeeper nfs-common sysstat)

echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -plow unattended-upgrades
sed -ri "s/\/\/(.*-updates.*)/\1/" /etc/apt/apt.conf.d/50unattended-upgrades
cat <<EOF > /etc/apt/apt.conf.d/10periodic
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

git config --global user.name || git config --global user.name "root"
git config --global user.email || git config --global user.email "root@`hostname`"

if grep '#VCS="git"' /etc/etckeeper/etckeeper.conf; then
  yes | etckeeper uninit
  sed -i -e 's/^VCS="bzr"/#VCS="bzr"/g' -e 's/^#VCS="git"/VCS="git"/g' /etc/etckeeper/etckeeper.conf
  cd /etc
  etckeeper init
fi

rm -f /tmp/uinit
