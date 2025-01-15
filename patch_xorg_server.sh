#!/bin/sh
# xorg-server has a bug in which the highest area at the very top of the desktop is
# unselectable. This is caused by rounding errors in mi/mipointer.c and can be fixed
# by using floor unstead of trunc
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

CHRWD="chroot_xserver"
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
APTSRC="xorg-server"

printf "deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse\n#deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse" > /etc/apt/sources.list

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
apt-get -y install debhelper libxcvt-dev libtirpc-dev libxcb-xinput-dev quilt \
                   systemd-dev dpkg-dev

# create a fresh project directory
cd /tmp

# acquire source for xorg-server and cd into it
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
  * Fix crash, replace four occurences of trunc to floor
    - applying commit 0ee4ed286ea238e2ba2ca57227c3e66aca11f56b from
      https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/1451/commits
CHEOF
printf "\n${LAST}\n\n" >> /tmp/latest_changes
sed -i -e '1 e cat /tmp/latest_changes' debian/changelog

# replace dependency which depends on ${source:Version} to $CURRENT
# xserver-common is placed a line after Depends:
sed -i "/^Depends:/{n;s/\(xserver-common.*(\).*\${source:Version}/\1>= $CURRENT/}" debian/control

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
  # new .deb file is in parent directory which needs to be installed from /tmp
fi
EOF

# get back from chroot
cd /tmp/chroot_xserver/tmp/
TDF=$(find * -maxdepth 1 -type f -name "xserver-xorg-core_*.deb" | head -n 1)
if [ -n "${TDF}" ]; then
  sudo apt-get -y --allow-downgrades install /tmp/chroot_xserver/tmp/${TDF}
else
  echo "Unable to find xorg-server-core debian file. Not installing."
fi
sudo rm -Rf /tmp/chroot_xserver


















