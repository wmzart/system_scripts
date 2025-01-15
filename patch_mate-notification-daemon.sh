#!/bin/sh
# mate-notification-daemon has a bug in which causes a random crash, mostly
# notable when a new e-mail arrives in evolution.
#
# This script fixes this. It creates a new deb package from the existing one and
# installs this subsequently. It does this in a chroot environment, preventing
# the system to get cluttered further.
#
# target system: ubuntu 24.04 (noble)
#
# References:
# https://github.com/mate-desktop/mate-notification-daemon/pull/229
# https://ubuntu-mate.community/t/how-to-replace-mates-notification-daemon-and-customize-it/6823
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

# dive into chroot now
echo "$(hostname)" | sudo tee "/tmp/${CHRWD}/etc/hostname"
cat << 'EOF' | sudo chroot "/tmp/${CHRWD}"
printf "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse\n#deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse" > /etc/apt/sources.list
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
apt-get -y install debhelper dpkg-dev autoconf-archive autopoint clang clang-tools git gobject-introspection gtk-doc-tools libcanberra-gtk3-dev libdconf-dev libexempi-dev libexif-dev libgail-3-dev libgirepository1.0-dev libglib2.0-dev libgtk-3-dev libmate-desktop-dev libmate-panel-applet-dev libnotify-dev libpango1.0-dev libstartup-notification0-dev libwnck-3-dev libx11-dev libxml2-dev libxml2-utils mate-common quilt shared-mime-info libgtk-layer-shell-dev
# create a fresh project directory
cd /tmp
# acquire source for xorg-server and cd into it
apt source mate-notification-daemon
VFD=$(find * -maxdepth 1 -type d -name "mate-notification-daemon*" | head -n 1)
cd ${VFD}
# replace single occurences of exit(0) with gtk_main_quit()
if [ $(grep -o "exit(0)" src/daemon/daemon.c | wc -l) -eq 1 ]; then
  sed -i 's/exit(0);/gtk_main_quit();/g' src/daemon/daemon.c
  echo "changed exit(0); into gtk_main_quit();"
  # for getting dependencies, remove unneccesary part from provided script and execute

  # build and create new deb file
  dpkg-buildpackage -rfakeroot -uc -b
  # new .deb file is directory lower: mate-notification-daemon_*.deb*, which needs to be installed from /tmp
fi
EOF

# get back from chroot
cd "/tmp/${CHRWD%/}/tmp"
TDF=$(find * -maxdepth 1 -type f -name "mate-notification-daemon_*amd64.deb" | head -n 1)
if [ -n "${TDF}" ]; then
  sudo apt-get -y --allow-downgrades install "/tmp/${CHRWD%/}/tmp/${TDF}"
else
  echo "Unable to find mate-notification-daemon_X.XX.X-XXXXXX.deb file"
fi
sudo rm -Rf "/tmp/${CHRWD}"
