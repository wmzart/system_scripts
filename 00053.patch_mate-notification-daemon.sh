#!/bin/sh
# mate-notification-daemon has a bug in which it crashes when monitor changes 
# during network events.
# the daemon could use an invalid monitor index to look up the notification
# stack, causing a segfault.
#
# This script fixes this.
#
# target system: ubuntu 24.04 (noble)
#
# References:
# https://github.com/mate-desktop/mate-notification-daemon
# https://github.com/mate-desktop/mate-notification-daemon/pull/258
# https://github.com/mate-desktop/mate-notification-daemon/commit/2ea0233c2a547e062206b2e1d3cc6ad067eba85c
# https://github.com/mate-desktop/mate-notification-daemon/issues/257
#
# created by Marc Nijdam, Jun. 2026
#
# license: MIT
#

# refresh apt and install some dependencies
sudo apt-get update


# install dependencies
sudo apt-get -y install libcanberra-gtk3-dev libglib2.0-dev \
                libgtk-3-dev libgtk-layer-shell-dev \
                libmate-desktop-dev libmate-panel-applet-dev \
                libnotify-dev libwnck-3-dev libx11-dev \
                libxml2-dev libxml2-utils mate-common autopoint

# create a project directory and create a clone of mate-notification-daemon:
mkdir -p ~/Maintenance/apps/
cd !$
git clone https://github.com/mate-desktop/mate-notification-daemon.git

# cd into repository and prepare build
cd mate-notification-daemon
./autogen.sh --prefix=/usr
# Now type `make' to compile mate-notification-daemon
make
# install
sudo make install

# execute and place in background
/usr/libexec/mate-notification-daemon/mate-notification-daemon &

# create startup item
q="[Desktop Entry]\n"
q="${q}Type=Application\n"
q="${q}Name=mate notification daemon\n"
q="${q}Exec=/usr/libexec/mate-notification-daemon/mate-notification-daemon\n"
q="${q}OnlyShowIn=Unity;MATE;XFCE;\n"
q="${q}NoDisplay=true\n"
q="${q}StartupNotify=false\n"
q="${q}Terminal=false\n"
printf "${q}" | sudo tee /etc/xdg/autostart/mate-notification-daemon.desktop

# done
exit 0
