#!/bin/bash

old=`hostname`
new="$1"
read -p "Change hostname from \"$old\" to \"$new\"? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	sudo true
	set -v
	sudo hostnamectl set-hostname $new
	sudo sed -i"" "s#$old#$new#" /etc/hosts
fi
