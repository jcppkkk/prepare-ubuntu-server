#!/bin/bash
# curl -sL http://git.io/uinit | bash
trap 'echo "Error: Script ${BASH_SOURCE[0]} Line $LINENO"' ERR
set -o errtrace # If set, the ERR trap is inherited by shell functions.
set -e

# auto sudo
if (( $(id -u) != 0 )); then
    exec sudo -H bash "$0" "$@"
fi

# use a local copy in case need to modify it
task_download_to_local()
{
    LOCAL_FILENAME=prepare-ubuntu-server.sh
    # allow local edit
    if [[ ! -f "$0" ]]; then
        echo "Download setup.sh to PWD..."
        curl -sL http://git.io/uinit > $LOCAL_FILENAME
        chmod u+x $LOCAL_FILENAME
        exec bash $LOCAL_FILENAME "$@"
    fi
}

task_script_env_header()
{
    hash apt-get  2>/dev/null && PKGCMD=apt-get
    hash apt      2>/dev/null && PKGCMD=apt
    hash aptitude 2>/dev/null && PKGCMD=aptitude
    hash dialog   2>/dev/null || { $PKGCMD -yq update && $PKGCMD -y install dialog; }
    REPO=$(dialog --clear --menu "Choose one of the following options:" 20 60 10 $(curl http://mirrors.ubuntu.com/mirrors.txt| nl) 2>&1 >/dev/tty)
    APT_REPO_URL=$(curl http://mirrors.ubuntu.com/mirrors.txt | tail -n +$REPO | head -n 1)
    echo "================================"
    export DEBIAN_FRONTEND=noninteractive
    printf '%-20s %s\n' package-command     $PKGCMD
    printf '%-20s %s\n' apt-repository      ${APT_REPO_URL}
    printf '%-20s %s\n' sudo-nopass-User    ${SudoNopass_User:=${SUDO_USER}}
    printf '%-20s %s\n' sudo-config         ${SudoNopass_Config:=/etc/sudoers.d/50_${SUDO_USER}_sh}
    echo "================================"
}

task_system_setup_repo()
{
    if [ -e /etc/lsb-release ]; then
        source /etc/lsb-release
        cat <<-EOF > /etc/apt/sources.list
deb $APT_REPO_URL $DISTRIB_CODENAME main restricted universe multiverse
deb $APT_REPO_URL $DISTRIB_CODENAME-security main restricted universe multiverse
deb $APT_REPO_URL $DISTRIB_CODENAME-updates main restricted universe multiverse
deb $APT_REPO_URL $DISTRIB_CODENAME-backports main restricted universe multiverse
deb-src $APT_REPO_URL $DISTRIB_CODENAME main restricted universe multiverse
deb-src $APT_REPO_URL $DISTRIB_CODENAME-security main restricted universe multiverse
deb-src $APT_REPO_URL $DISTRIB_CODENAME-updates main restricted universe multiverse
deb-src $APT_REPO_URL $DISTRIB_CODENAME-backports main restricted universe multiverse
# $(date --rfc-3339=seconds) Auto generated by jcppkkk/prepare-ubuntu-server
EOF
        $PKGCMD -yq update
    fi
}

task_system_setup_sudo_nopass()
{
    if ! grep -q "^#includedir.*/etc/sudoers.d" /etc/sudoers;then
        echo "#includedir /etc/sudoers.d" >> /etc/sudoers
    fi
    (
        umask 226
        echo "$SudoNopass_User ALL=(ALL) NOPASSWD:ALL" > "$SudoNopass_Config"
    )
}

task_system_config_tz()
{
    $PKGCMD install -y python3-distutils python3-setuptools python3-pip
    pip3 install -U pip tzupdate
    tzupdate 2>/dev/null
}

task_unattended_upgrades()
{
    echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
    dpkg-reconfigure -plow unattended-upgrades
    sed -ri "s/\/\/(.*-updates.*)/\1/" /etc/apt/apt.conf.d/50unattended-upgrades
    cat <<-EOF > /etc/apt/apt.conf.d/10periodic
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
}

task_purge_old_kernels()
{
    if [[ -n "$(\which purge-old-kernels)" ]]; then
        ln -fs $(\which purge-old-kernels) /etc/cron.daily/
        purge-old-kernels
    fi
}

task_download_to_local $@
task_script_env_header $@

# Update source list to local mirror
task_system_setup_repo

# Auto config timezone
$PKGCMD install -y ntp git
task_system_config_tz

# Clean up old kernel
task_purge_old_kernels
$PKGCMD autoremove

# Upgrade system packages
$PKGCMD full-upgrade -y

# Setup unattended upgrades
read -e -p "Setup unattended upgrades? [y/n] " -i "y" ANS
if [[ "$ANS" == y ]]; then
    $PKGCMD install -y unattended-upgrades
    task_unattended_upgrades
fi

# Setup user ubuntu to nopass
task_system_setup_sudo_nopass

# Setup user config
su - ${SUDO_USER} -c "grep -q 'EDITOR=vim' ~/.bashrc || echo 'EDITOR=vim' >> ~/.bashrc"
