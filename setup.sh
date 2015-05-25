# curl -sL http://git.io/uinit | bash
set -x

if [ "$UINIT_SCRIPT" != "yes" ]; then
  if [ -f "$0" ]; then
    cp "$0" /tmp/uinit
  else
    curl -sL http://git.io/uinit > /tmp/uinit
  fi
  sudo UINIT_SCRIPT=yes bash /tmp/uinit
  exit
fi

export DEBIAN_FRONTEND=noninteractive

grep -q "^#includedir.*/etc/sudoers.d" /etc/sudoers || echo "#includedir /etc/sudoers.d" >> /etc/sudoers
( umask 226 && echo "${SUDO_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/50_${SUDO_USER}_sh )

grep -q 'EDITOR=vim' ~/.bashrc || echo 'EDITOR=vim' >> ~/.bashrc
grep -q 'for linux console' ~/.inputrc || echo '"\eOA": history-search-backward
"\eOB": history-search-forward
"\e[A": history-search-backward
"\e[B": history-search-forward
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On
set completion-ignore-case On
set visible-stats On
set show-all-if-ambiguous on
set show-all-if-unmodified on' | tee ~/.inputrc

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
aptitude install -y squid-deb-proxy-client

# Auto Update pkgs
# auto adjust server time
# Record /etc changes
aptitude install -y unattended-upgrades ntp git etckeeper 
aptitude safe-upgrade  -y

sed -i 's/Download-Upgradeable-Packages "0";/Download-Upgradeable-Packages "1";/g' /etc/apt/apt.conf.d/10periodic
sed -i 's/AutocleanInterval "0";/AutocleanInterval "7";/g' /etc/apt/apt.conf.d/10periodic
echo 'APT::Periodic::Unattended-Upgrade "1";' | tee -a /etc/apt/apt.conf.d/10periodic


if grep '#VCS="git"' /etc/etckeeper/etckeeper.conf; then
  yes | etckeeper uninit
  sed -i -e 's/^VCS="bzr"/#VCS="bzr"/g' -e 's/^#VCS="git"/VCS="git"/g' /etc/etckeeper/etckeeper.conf
  cd /etc
  etckeeper init
fi

rm -f /tmp/uinit
