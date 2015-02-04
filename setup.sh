echo '"\eOA": history-search-backward
"\eOB": history-search-forward
"\e[A": history-search-backward
"\e[B": history-search-forward
# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert
#TAB: menu-complete
# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

set completion-ignore-case On
set visible-stats On

# to produce a list of all possible completions only when no completion is possible
set show-all-if-ambiguous on
set show-all-if-unmodified on' | tee ~/.inputrc
bind -f ~/.inputrc

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
"| sudo tee /etc/apt/sources.list;
sudo apt-get update
sudo apt-get -y upgrade
