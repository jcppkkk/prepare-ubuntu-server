#!/bin/bash
trap 'echo "Error: Script ${BASH_SOURCE[0]} Line $LINENO"' ERR
set -o errtrace # If set, the ERR trap is inherited by shell functions.
set -e

id

if [[ $(id -u) != 0 ]]; then
    echo "Requires root privilege"
    exit 1
fi
set -v
# Add VMware package keys
wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub -O - | apt-key add -
apt-get update
apt-get install -y open-vm-tools

# Upgrade system
apt-get dist-upgrade -y

# Clear audit logs
service rsyslog stop
if [ -f /var/log/audit/audit.log ]; then
    cat /dev/null > /var/log/audit/audit.log
fi
if [ -f /var/log/wtmp ]; then
    cat /dev/null > /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    cat /dev/null > /var/log/lastlog
fi

# Cleanup persistent udev rules
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
    rm /etc/udev/rules.d/70-persistent-net.rules
fi

# Cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

# Cleanup current ssh keys
service ssh stop
rm -f /etc/ssh/ssh_host_*

# Check for ssh keys on reboot...regenerate if neccessary
cat <<EOL | sudo tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server
exit 0
EOL
chmod u+x /etc/rc.local

# Reset hostname
cat /dev/null > /etc/hostname

# Cleanup apt
apt clean

# Zerofree Disk
cat /dev/zero >> /zero; rm -f /zero

# Cleanup shell history
history -c
history -w

# Shutdown
shutdown -P now
