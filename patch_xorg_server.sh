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

[ -d /tmp/xorg_chroot ] && sudo rm -Rf /tmp/xorg_chroot
sudo mkdir -p /tmp/xorg_chroot

# create chroot
sudo debootstrap \
  --variant=minbase \
  --arch=amd64 noble \
  /tmp/xorg_chroot \
  http://archive.ubuntu.com/ubuntu

# dive into chroot now
echo "$(hostname)" | sudo tee /tmp/xorg_chroot/etc/hostname
cat << 'EOF' | sudo chroot /tmp/xorg_chroot
printf "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse\ndeb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse" > /etc/apt/sources.list
# enable sources in apt
histchars=
q="Types: deb deb-src\n"
q="${q}URIs: http://de.archive.ubuntu.com/ubuntu/\n"
q="${q}Types: deb deb-src\n"
q="${q}URIs: http://de.archive.ubuntu.com/ubuntu/\n"
q="${q}Suites: noble noble-updates noble-backports\n"
q="${q}Components: main restricted universe multiverse\n"
q="${q}Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n\n"
q="${q}Types: deb deb-src\n"
q="${q}URIs: http://security.ubuntu.com/ubuntu/\n"
q="${q}Suites: noble-security\n"
q="${q}Components: main restricted universe multiverse\n"
q="${q}Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg"
printf "${q}\n" > "/etc/apt/sources.list.d/ubuntu.sources"
unset histchars
# refresh apt and install some dependencies
apt update
apt-get -y install debhelper libxcvt-dev libtirpc-dev libxcb-xinput-dev quilt systemd-dev dpkg-dev
# create a fresh project directory
cd /tmp
# acquire source for xorg-server and cd into it
apt source xorg-server
VFD=$(find * -maxdepth 1 -type d -name "xorg-server*" | head -n 1)
cd ${VFD}
# replace all 4 occurences of trunc with floor
if [ $(grep -o trunc mi/mipointer.c | wc -l) -eq 4 ]; then
  sed -i 's/trunc/floor/g' mi/mipointer.c
  echo "changed trunc into floor"
  # for getting dependencies, remove unneccesary part from provided script and execute
  sed -i '/cross-prereqs-build.sh i686-w64-mingw32/,$d' .gitlab-ci/debian-install.sh
  chmod +x .gitlab-ci/debian-install.sh
  .gitlab-ci/debian-install.sh
  # build and create new deb file
  dpkg-buildpackage -rfakeroot -uc -b
  # new .deb file is directory lower: xserver-xorg-core_*, which needs to be installed from /tmp
fi
EOF

# get back from chroot
cd /tmp/xorg_chroot/tmp/
TDF=$(find * -maxdepth 1 -type f -name "xserver-xorg-core_*.deb" | head -n 1)
if [ -n "${TDF}" ]; then
  sudo apt-get -y --allow-downgrades install /tmp/xorg_chroot/tmp/${TDF}
else
  echo "Unable to find xorg-server-core.XXYYZZ.deb file"
fi
sudo rm -Rf /tmp/xorg_chroot
