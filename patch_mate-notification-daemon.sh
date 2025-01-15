#!/bin/sh
# xorg-server has a bug in which the highest area at the very top is unselectable
# This is caused by rounding errors in /mi/mipointer.c and can be fixed by using
# floor unstead of trunc
#
# This script fixes this. It creates a new deb package from the existing one and
# installs this subsequently. It does this in a chroot environment, preventing
# the system to get cluttered further.
#
# target system: ubuntu 24.04 (noble)
#
# References:
# https://bugs.launchpad.net/ubuntu/+source/xorg-server/+bug/1795135
# https://ubuntu-mate.community/t/tip-to-fix-un-clickable-menu-and-show-desktop-buttons/19928
# https://bugs.launchpad.net/plank/+bug/1505440
# https://bugs.launchpad.net/plank/+bug/1828002
# https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/1451
#
# created by Marc Nijdam, Jan. 2025
#
# license: MIT
#
command -v debootstrap 2>&1 >/dev/null || { echo 'Unable to find debootstap. Please install with "sudo apt install debootstrap". Aborting.'; exit 1; }

CHRWD="chroot_mate_notification_daemon"
MIRROR="http://archive.ubuntu.com/ubuntu"

[ -d "/tmp/${CHRWD}" ] && sudo rm -Rf "/tmp/${CHRWD}"
sudo mkdir -p "/tmp/${CHRWD}"

# create chroot
sudo debootstrap --variant=minbase --arch=amd64 noble "/tmp/${CHRWD}" ${MIRROR}

# prepare system variables hostname and locale.gen
echo "$(hostname)" | sudo tee "/tmp/${CHRWD}/etc/hostname"
sudo cp /etc/locale.gen "/tmp/${CHRWD}/etc/"

# dive into chroot now
cat << 'EOF' | sudo chroot "/tmp/${CHRWD}"
# target deb file
APTSRC="mate-notification-daemon"

# add sources for apt
printf "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse\n" > /etc/apt/sources.list

# enable src sources in apt
cat <<AEOF > "/etc/apt/sources.list.d/ubuntu.sources"
Types: deb deb-src
URIs: http://de.archive.ubuntu.com/ubuntu/
Types: deb deb-src
URIs: http://de.archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb deb-src
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
AEOF

# refresh apt and install some dependencies
apt update

# install and generate localisation files from previously copied locale from host system
apt-get -y install libreadline6-dev locales
locale-gen

# install dependencies
apt-get -y install debhelper dpkg-dev autoconf-archive autopoint clang \
                   clang-tools git gobject-introspection gtk-doc-tools \
                   libcanberra-gtk3-dev libdconf-dev libexempi-dev libexif-dev \
                   libgail-3-dev libgirepository1.0-dev libglib2.0-dev \
                   libgtk-3-dev libmate-desktop-dev libmate-panel-applet-dev \
                   libnotify-dev libpango1.0-dev libstartup-notification0-dev \
                   libwnck-3-dev libx11-dev libxml2-dev libxml2-utils \
                   mate-common quilt shared-mime-info libgtk-layer-shell-dev

# create a fresh project directory
cd /tmp

# acquire source for mate_notification_daemon and cd into it
apt source "${APTSRC}"
VFD=$(find * -maxdepth 1 -type d -name "${APTSRC}*" | head -n 1)
cd ${VFD}

# update debian changelog.
CURRENT=$(dpkg-parsechangelog --show-field Version)
NEWER=$(perl -spe 's/(\d+)(?!.*\d+)/$1>$thresh? $1+1 : $1/e' <<< ${CURRENT})
AUTHOR="Marc Nijdam <dev@nijdam.de>"
FIRST="${APTSRC} (${NEWER}) noble; urgency=medium"
LAST=" -- ${AUTHOR}  $(date -R)"
printf "${FIRST}\n\n" > /tmp/latest_changes
cat <<CHEOF >> /tmp/latest_changes
  * Fix crash, replace single occurence of exit(0) with gtk_main_quit()
    - applying commit 11775c94136b4f64800e0136d48c5cff41b0692c from
      https://github.com/mate-desktop/mate-notification-daemon/pull/229
CHEOF
printf "\n${LAST}\n\n" >> /tmp/latest_changes
sed -i -e '1 e cat /tmp/latest_changes' debian/changelog

# replace dependency which depends on ${source:Version} to $CURRENT
# to ${CURRENT}
sed -i "G;/^Depends: /s/\${source:Version}/$CURRENT/;s/\n.*//;h" debian/control

# replace single occurence of exit(0) with gtk_main_quit()
if [ $(grep -o "exit(0)" src/daemon/daemon.c | wc -l) -eq 1 ]; then
  sed -i 's/exit(0);/gtk_main_quit();/g' src/daemon/daemon.c
  echo "changed exit(0); into gtk_main_quit();"

  # build and create new deb file
  dpkg-buildpackage -rfakeroot -uc -b
  # new .deb file is in parent directory which needs to be installed from /tmp
fi
EOF

# get back from chroot
cd "/tmp/${CHRWD%/}/tmp"
TDF=$(find * -maxdepth 1 -type f -name "mate-notification-daemon_*amd64.deb" | head -n 1)
if [ -n "${TDF}" ]; then
  sudo apt-get -y install "/tmp/${CHRWD%/}/tmp/${TDF}"
else
  echo "Unable to find mate-notification-daemon debian file. Not installing."
fi
sudo rm -Rf "/tmp/${CHRWD}"
