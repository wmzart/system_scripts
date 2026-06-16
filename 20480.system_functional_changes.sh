#!/bin/sh

# This module configures the following:
#   * setting system locale to en_GB
#   * enabling source code for apt with ubuntu software
#   * caja default folder-viewer to list-view
#   * caja default action to view executables text files (when opening sh files)
#   * caja view settings for text in icons to never
#   * system clock to 24h
#   * optimizing gnome blank screen and lock screen settings
#   * pluma color scheme to Yaru-dark
#   * terminal scrollback-lines to 999999
#   * prevent that printers are automatically added
#   * make vim the default command line editor
#   * add user to dialout group for accessing /dev/ttyUSB0 as non-root user
#   * change/move profile directory to be within directory ~/backup/
#   * change F2 to 'Enter' for renaming in caja (*)
#   * fixes a bug in xorg-xserver which makes the top edge menu unselectable
#   * creates a desktop icon, mimetypes and file icon for freecad (**)
#   * adds a samba share for QEMU/KVM
#   * enables smooth scrolling in Firefox
#   * Improve some common aliases to $HOME/.bash_aliases
#     * xclip makes it possible to pipe a file into the normal clipboard
#     * use legacy SCP protocol
#   * if necessary, configure libvirt for a provided virtual machine (***) 
# * and installs the following:
#   * git
#   * meld
#   * dconf-editor
#   * build-essential
#   * usb-creator-gtk
#   * disks (gnome-disk-utility)
#   * debootstrap
#   * apport-retrace
#   * vim
#   * timeshift (optional)
#   * vlc (optional)
#   * QEMU/KVM Virtual Machine Manager
#   * openvpn if file *.opvn is present on usb disk and was not installed before
#   * xcalib for mimicking osx-like invert screen feature
#   * caja image converter tools
#   * libvirt (only if a valid machine defintions file is found on USB disk)


# (*) Please note that this option only works to 'enter/go into' renaming mode,
#     similar as with OSX. Unfortunately pressing a second time on enter does
#     not make the change to go into effect, but selects the whole text, if it
#     includes an extension. As long as this is not solved, the user needs to
#     press SHIFT + Enter to effectuate/proceed.
#
# (**) But only if freecad was installed previously
#
# (***) On the condition that a virt_.*.tar.bz2 is provided with settings
#       Please note that the virtual machine itself should be already copied
#       over to the location where it was before.
#       (For example $HOME/backup/virtual_imgs/debian/)
#
# Author: Marc Nijdam, Dec. 2025
# License: MIT


## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done


## verify environment variables
if [ -z "${HOME#/home/}" ]; then
  echo "unable to proceed with unspecified user: \$${HOME#/home/} undefined"
  exit 1
fi


REBOOT=0
echo ">>>> ATTENTION: ABOUT TO CONFIGURE SYSTEM. READ CAREFULLY!"
if ps ax -ocomm | grep -q "[f]irefox"; then
  echo "Please close firefox first, Then rerun this script. Aborting."
  exit 1
fi
startsudo
# setting locale: https://www.tecmint.com/set-system-locales-in-linux/
if ! locale | grep -q "LANG=en_GB.UTF-8"; then
  printf ">>    Setting locale: en_GB.UTF-8 (dot for decimals) ..."
  sudo localectl set-locale LANG=en_GB.UTF-8
  printf "done.\n"
  # enable new locale
  . /etc/default/locale
  REBOOT=1
fi
sudo apt update
# adding source code for ubuntu software system
# Ref. https://askubuntu.com/questions/1512042/ubuntu-24-04-getting-error-you-must-put-some-deb-src-uris-in-your-sources-list
if ! grep -q "Types: deb deb-src" /etc/apt/sources.list.d/ubuntu.sources; then
  printf ">>    Adding source code for ubuntu software to system..."
  sudo sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
  printf "done.\n"
fi  
# install required prerequisites
# consider instead of usb-creator-gtk usbimager
# ref. https://gitlab.com/bztsrc/usbimager
printf ">>    installing git, meld, dconf-editor, build-essential, usb-creator, disks ...\n"
sudo apt-get -y install build-essential git meld dconf-editor \
                        usb-creator-gtk gnome-disk-utility debootstrap \
                        apport-retrace
printf "Done.\n"
printf ">>    (re)setting caja default folder-viewer to list-view... "
gsettings set org.mate.caja.preferences default-folder-viewer 'list-view'
printf "done.\n"
printf ">>    (re)setting caja default action to view executables text files... "
gsettings set org.mate.caja.preferences executable-text-activation 'display'
printf "done.\n"
printf ">>    (re)setting caja view settings for text in icons to never... "
gsettings set org.mate.caja.preferences show-icon-text 'never'
printf "done.\n"
printf ">>    (re)setting clock to 24h system..."
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.ayatana.indicator.datetime time-format '24-hour'
printf "done.\n"
printf ">>    (re)optimizing gnome blank screen and lock screen settings... "
gsettings set org.gnome.desktop.session idle-delay 1800
gsettings set org.gnome.desktop.screensaver lock-delay 1800
printf "done.\n"
printf ">>    (re)setting pluma color scheme to Yaru-dark... "
gsettings set org.mate.pluma color-scheme 'Yaru-dark'
printf "done.\n"
printf ">>    (re)setting terminal scrollback-lines to 999999... "
gsettings set org.mate.terminal.profile:/org/mate/terminal/profiles/default/ scrollback-lines 999999
printf "done.\n"
printf ">>    prevent that printers are automatically added... "
# https://askubuntu.com/questions/1501164/turn-off-printer-discovery
# https://forums.linuxmint.com/viewtopic.php?p=2086822#p2086822
# https://forums.linuxmint.com/viewtopic.php?t=378365
# https://askubuntu.com/questions/345083/how-do-i-disable-automatic-remote-printer-installation/556963
# https://raw.githubusercontent.com/OpenPrinting/cups-browsed/refs/heads/master/daemon/cups-browsed.conf.in
if ! grep -q '^BrowseProtocols none$' /etc/cups/cups-browsed.conf; then
  # uncomment the line with "# BrowseProtocols none"
  sudo sed -i '/BrowseProtocols none/s/^#*\s*//g' /etc/cups/cups-browsed.conf
  printf "done. (but restart for having effect). \n"
  # #enable-dbus=yes
  # edit /etc/avahi/avahi-daemon.conf and in the [server] section, add enable-dbus=no then restart the avahi-daemon service.
  # disable mDNS protocol at printer
fi

## vim
if ! command -v vim 2>&1 >/dev/null; then
  printf "Shall vim be installed and be the default command line editor (y/n)? "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    printf ">>    installing vim, making it the default command line editor...\n"
    sudo apt-get -y install vim
    sudo update-alternatives --set editor /usr/bin/vim.basic
    sudo update-alternatives --set vi /usr/bin/vim.basic
    printf "Done.\n"
  fi
fi

## add user to dialout group for accessing /dev/ttyUSB0 as non-root user
if [ "$(getent group dialout | awk -F':' '{print $4}')" != "${HOME#/home/}" ]; then
  sudo usermod -a -G dialout "${HOME#/home/}"
  printf "Adding user ${HOME#/home/} to the dialout group.\n"
  REBOOT=1
else
  printf "user ${HOME#/home/} is already member of the group dialout. Skipping.\n"
fi

## use timeshift to backup/restore the linux system to specific dates
# Timeshift helps during the initial period when setting up a system
# Especially, when installing and removing dependencies with apt,
# to compile some application, havoc can happen.
# Therefore this tool helps a lot to bring the system back to a certain
# date when everything was still healthy.
# https://www.linuxtechi.com/timeshift-backup-restore-ubuntu-linux/
if ! command -v timeshift 2>&1 >/dev/null; then
  printf "Do you wish to install timeshift (y/n)? "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    printf ">>    installing timeshift...\n"
    sudo apt-get -y install timeshift
    printf "Done.\n"
  fi
fi

## install vlc to play all kind of media files
if ! command -v vlc 2>&1 >/dev/null; then
  printf "Do you wish to install vlc as media player (y/n)? "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    printf ">>    installing vlc...\n"
    sudo apt-get -y install vlc
    printf "Done.\n"
  fi
fi

## change default profile paths
userdirs="$HOME/.config/user-dirs.dirs"  
# Create backup if not already exists
if [ ! -e ${userdirs}_ORIG ]; then
  printf "Do you wish to move default profile directories into ~/backup/ (y/n)? "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    cp ${userdirs} ${userdirs}_ORIG
    # Create all corresponding directories for synchronization
    [ -d $HOME/${NEW_PROFILE_DIR%/}/Pictures ] || mkdir -p $HOME/${NEW_PROFILE_DIR%/}/Pictures
    sed -i "s|^XDG_PICTURES_DIR=.*|XDG_PICTURES_DIR=\"\$HOME/${NEW_PROFILE_DIR%/}/Pictures\"|g" ${userdirs}
    [ -d $HOME/${NEW_PROFILE_DIR%/}/Documents ] || mkdir -p $HOME/${NEW_PROFILE_DIR%/}/Documents
    sed -i "s|^XDG_DOCUMENTS_DIR=.*|XDG_DOCUMENTS_DIR=\"\$HOME/${NEW_PROFILE_DIR%/}/Documents\"|g" ${userdirs}
    [ -d $HOME/${NEW_PROFILE_DIR%/}/Templates ] || mkdir -p $HOME/${NEW_PROFILE_DIR%/}/Templates
    sed -i "s|^XDG_TEMPLATES_DIR=.*|XDG_TEMPLATES_DIR=\"\$HOME/${NEW_PROFILE_DIR%/}/Templates\"|g" ${userdirs}
    [ -d $HOME/${NEW_PROFILE_DIR%/}/Music ] || mkdir -p $HOME/${NEW_PROFILE_DIR%/}/Music
    sed -i "s|^XDG_MUSIC_DIR=.*|XDG_MUSIC_DIR=\"\$HOME/${NEW_PROFILE_DIR%/}/Music\"|g" ${userdirs}
    [ -d $HOME/${NEW_PROFILE_DIR%/}/Videos ] || mkdir -p $HOME/${NEW_PROFILE_DIR%/}/Videos
    sed -i "s|^XDG_VIDEOS_DIR=.*|XDG_VIDEOS_DIR=\"\$HOME/${NEW_PROFILE_DIR%/}/Videos\"|g" ${userdirs}
    # And create symbolic links to the user directories, but only if these are empty.
    # If not empty, copy from source to target directory.
    rmdir $HOME/Pictures && ln -s $HOME/${NEW_PROFILE_DIR%/}/Pictures $HOME/Pictures
    rmdir $HOME/Documents && ln -s $HOME/${NEW_PROFILE_DIR%/}/Documents $HOME/Documents
    rmdir $HOME/Templates && ln -s $HOME/${NEW_PROFILE_DIR%/}/Templates $HOME/Templates
    rmdir $HOME/Music && ln -s $HOME/${NEW_PROFILE_DIR%/}/Music $HOME/Music
    rmdir $HOME/Videos && ln -s $HOME/${NEW_PROFILE_DIR%/}/Videos $HOME/Videos
    printf "Done.\n"
  fi
fi

## change F2 to 'Enter' for renaming in caja
# please note that when in entering mode, the enter key itself cannot be used to confirm the setting.
# instead use SHIFT + Enter
# See here: https://github.com/mate-desktop/caja/issues/1794
if ! grep -q -e '^(gtk_accel_path "<Actions>/DirViewActions/Rename" "Return")' ~/.config/caja/accels; then
  printf "Do you wish to set shortcut key 'Enter' in caja for renaming files (y/n)? "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    caja -q; sed -i 's/.*DirViewActions\/Rename\".*/\(gtk_accel_path \"<Actions>\/DirViewActions\/Rename\" \"Return\"\)/g' ~/.config/caja/accels
    sleep 0.5
    printf "Done.\n"
  fi
fi

## Fix top edge menu unselectable
# This fixes two bugs: 1 pixel at the top not selectable and crashing plank dock when moving icons 
# https://bugs.launchpad.net/ubuntu/+source/xorg-server/+bug/2103703
# https://bugs.launchpad.net/ubuntu/+source/xorg-server/+bug/1795135
# https://ubuntu-mate.community/t/tip-to-fix-un-clickable-menu-and-show-desktop-buttons/19928
# https://bugs.launchpad.net/plank/+bug/1505440
# https://bugs.launchpad.net/plank/+bug/1828002
# https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/1451
# https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/1451/commits
# https://gitlab.freedesktop.org/xorg/xserver/-/merge_requests/1451/diffs?commit_id=0ee4ed286ea238e2ba2ca57227c3e66aca11f56b
# https://github.com/wmzart/system_scripts/blob/main/patch_xorg_server.sh
#
# save the following to a /etc/apt/preferences file.
# Package: xserver-xorg-core
# Pin: version 2:21.1.12-1ubuntu1.3
# Pin-Priority: -1
#
# use "sudo apt-mark auto xserver-xorg-core" to mark packages as automatically being installed.
# use "sudo apt-mark manual xserver-xorg-core" to mark packages as manually being installed.
# use "sudo apt-mark hold xserver-xorg-core" to prevent a package from being automatically installed.
# see man apt-mark for more info.
#
# At least xserver-xorg-core versions 2:21.1.12-1ubuntu1.3 and
# 2:21.1.12-1ubuntu1.5 contain the rounding issue with trunc instead of floor
# and will be patched/rebuilt as a version with, for the last digit, a version
# number one higher.
XPATCH="00050.patch_xserver-xorg-core.sh"
MND_TARGET="xserver-xorg-core"
LATEST_UBUNTU_VER="$(apt-cache madison "${MND_TARGET}" | tail -n 1 | awk '{print $3}')"
OBSERVED_VER="$(dpkg -l "${MND_TARGET}" | grep "${MND_TARGET}" | awk '{print $3}')"
if dpkg --compare-versions ${OBSERVED_VER} le ${LATEST_UBUNTU_VER}; then
      printf ">>    patching xserver with 1px top menu not selectable bug...\n"
  cp "$(dirname "$(realpath $0)")/${XPATCH}" /tmp/
  # build xorg-server with patch (in chroot) and install with apt (from within /tmp)
  sh "/tmp/${XPATCH}"
  rm "/tmp/${XPATCH}"
  REBOOT=1
  printf ">>    patched ${MND_TARGET} installed ...\n"
  printf ">>    If necessary you may revert to the original with:\n"
  printf "sudo apt install --allow-downgrades ${MND_TARGET}=${LATEST_UBUNTU_VER}\n"
else
  printf ">>    patched ${MND_TARGET} already installed ...\n"
fi

## install desktop icon, mimetypes and file icon for freecad
# We are using an appimage version in $APPDIR/freecad/
# The script creates a symlink from /usr/local/bin/freecad to the appimage
# The desktop file executes freecad from /usr/local/bin/freecad
# It assumes, if a symlink is installed from within /usr/local/bin/ that also
# the desktop icons, mimetypes and file icon is present.
MND_TARGET="freecad"
if [ ! -d "${APPDIR%/}/${MND_TARGET}" ]; then
  echo "unable to find ${MND_TARGET} appimage in ${APPDIR}. Skipping."
else  
  if [ ! -h "/usr/local/bin/${MND_TARGET}" ]; then
    printf ">>    installing launcher for ${MND_TARGET} ...\n"
    sh "$(dirname "$(realpath $0)")/00051.create_${MND_TARGET}_launcher.sh"
    printf "Done.\n"
  else 
    printf ">>    ${MND_TARGET} launcher already installed. skipping."
  fi
fi

## install QEMU/KVM Virtual Machine Manager with samba share, but only if a file
# is found on USB disk in the format virt_POOLNAME.tar.bz2 then libvirt will be
# installed and configured for the system which is specified in the contained
# .xml file. The virtualized machine itself is already present on disk.
# Where POOLNAME corresponds to the name given by the command "virsh list --all"
get_mounted_drive "virt_*.tar.bz2" "quiet"
if [ "$?" = 0 ]; then
  if [ -z "${BSFN}" ]; then
    echo "No file found with a QEMU/KVM virtual machine configuration on USB disk. Skipping..."
  else
    printf ">>>> ATTENTION: archive ${BSFN} found.\n"
    printf "Do you wish to use this to configure QEMU/KVM (y/n)? "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then 
      sh "$(dirname "$(realpath $0)")/00052.libvirt_install.sh" "${MNTF%/}/${BSFN}"
      if [ "$?" = 0 ]; then
        printf "Done.\n"
      fi
    fi
  fi
else
  echo "Skipping to configure QEMU/KVM because either no USB drive was found or a file"
  echo "with virt definitions (virt_*.tar.bz2) is missing."
fi

## import openvpn ovpn file if present on usb disk and was not installed before.
#
# References:
# * https://superuser.com/questions/1695347/network-manager-store-secrets-for-automatic-openvpn-connection
# * https://serverfault.com/questions/483941/generate-an-openvpn-profile-for-client-user-to-import
# * https://networkmanager.dev/docs/api/latest/nmcli.html
# * https://gist.github.com/qiwichupa/2c1828232fd23258aeb78ac3808bd729
# * https://superuser.com/questions/1695347/network-manager-store-secrets-for-automatic-openvpn-connection
# * https://www.reddit.com/r/archlinux/comments/r1885f/etcnetworkmanagersystemconnections_is_blank/
# * https://bugs.launchpad.net/ubuntu-mate/+bug/1876467
get_mounted_drive "${VPN_ARCHIVE}*" "quiet"
if [ "$?" = 0 ]; then
  if [ -z "${BSFN}" ]; then
    echo "No ovpn file found with a vpn configuration on USB disk. Skipping..."
  else
    import_all_vpn_connections "${MNTF%/}/${BSFN}"
  fi
fi

## inverting screen feature
# keyboard shortcut for inverting screen: <CTRL> + <ALT> + 8
# It assumes if xcalib is present, then the invert modification was done already
INV_SCR_KBSCUT='<Primary><Alt><Mod4>8'
if ! dpkg-query -l | grep -q xcalib; then
  printf "Installing xcalib for mimicking osx-like invert screen feature...\n"
  sudo apt-get -y install xcalib
  printf "Done.\n"
  # ref. https://github.com/mate-desktop/mate-desktop/issues/561
  # ref. https://ubuntu-mate.community/t/how-to-add-custom-keybindings-using-gsettings/15941/5
  gsettings set org.mate.control-center.keybinding:/org/mate/desktop/keybindings/custom0/ action '/usr/bin/xcalib -i -a'
  gsettings set org.mate.control-center.keybinding:/org/mate/desktop/keybindings/custom0/ name 'Invert screen'
  gsettings set org.mate.control-center.keybinding:/org/mate/desktop/keybindings/custom0/ binding ${INV_SCR_KBSCUT}
  printf "Please use Ctrl+Windows+Alt+8 to invert screen.\n"
else
  printf "xcalib already installed...\n"
fi

## install caja image converter tools
# https://community.linuxmint.com/software/view/caja-image-converter
# https://archlinux.org/packages/extra/x86_64/caja-image-converter/
PACKAGE="caja-image-converter"
if ! dpkg-query -l | grep -q ${PACKAGE}; then
  printf "Installing ${PACKAGE} to get context enabled image resizing with caja file manager ...\n"
  sudo apt-get update && sudo apt-get upgrade
  sudo apt-get -y install ${PACKAGE}
  printf "Please note: To use caja image converter, restart caja with the following\n"
  printf "command: caja -q (or reboot system)"
  REBOOT=1 
else
  printf "${PACKAGE} is already installed. Skipping.\n"
fi

stopsudo
  
## Smooth scrolling in firefox
# see https://www.reddit.com/r/pop_os/comments/iwe0v9/how_to_get_precise_scrolling_in_firefox_with_your/
# and https://connect.mozilla.org/t5/ideas/implement-smoother-scrolling/idi-p/8035#
# and https://askubuntu.com/questions/32631/how-to-configure-firefox-from-terminal
if ! grep "MOZ_USE_XINPUT2=1" "$HOME/.xsessionrc"; then
  printf "\n# Pixel precise smooth scrolling in firefox\nexport MOZ_USE_XINPUT2=1\n" >> "$HOME/.xsessionrc"
fi
if [ -d "$HOME/.mozilla/firefox/" ]; then
  cd $HOME/.mozilla/firefox/
  if grep '\[Profile[^0]\]' profiles.ini; then
    PROFPATH=$(grep -E '^\[Profile|^Path|^Default' profiles.ini | grep -1 '^Default=1' | grep '^Path' | cut -c6-)
  else
    PROFPATH=$(grep 'Path=' profiles.ini | sed 's/^Path=//')
  fi
  cd $PROFPATH
  SMOOTHSCR=$(grep "general.smoothScroll" prefs.js)
  if [ -z "$SMOOTHSCR" ]; then
    echo 'user_pref("general.smoothScroll", true);' >> prefs.js
    sort -o prefs.js prefs.js
    printf "Smooth scrolling for firefox enabled.\n"
  else
    if echo $SMOOTHSCR | grep true; then
      printf "Smooth scrolling for firefox already enabled.\n"
    else
      sed -i -e 's/^user_pref("general.smoothScroll", \(false\));$/user_pref("general.smoothScroll", true);/' prefs.js
      printf "Smooth scrolling for firefox enabled.\n"
    fi
  fi
else
  echo "Skipping smooth scrolling for firefox, because there is no profile directory"
  echo "present at ~/.mozilla/firefox/"
  echo "Please rerun this script once firefox has been up and running."
fi


## Disable gestures for navigating to previous or next page in firefox
if [ -d "$HOME/.mozilla/firefox/" ]; then
  cd $HOME/.mozilla/firefox/
  if grep '\[Profile[^0]\]' profiles.ini; then
    PROFPATH=$(grep -E '^\[Profile|^Path|^Default' profiles.ini | grep -1 '^Default=1' | grep '^Path' | cut -c6-)
  else
    PROFPATH=$(grep 'Path=' profiles.ini | sed 's/^Path=//')
  fi
  cd $PROFPATH
  GESTURES=$(grep -e "browser.gesture.swipe.left" -e "browser.gesture.swipe.right" prefs.js)
  if [ -z "${GESTURES}" ]; then
    echo 'user_pref("browser.gesture.swipe.left", "");' >> prefs.js
    echo 'user_pref("browser.gesture.swipe.right", "");' >> prefs.js
    sort -o prefs.js prefs.js
    printf "Gestures for navigating back and forward are disabled in firefox.\n"
  else
    printf "Gestures for navigating back and forward are already disabled in firefox.\n"
  fi
else
  echo "Skipping gesture swiping for navigating back and forth in firefox, because"
  echo "there is no profile directory present at ~/.mozilla/firefox/"
  echo "Please rerun this script once firefox has been up and running."
fi


## Firefox: Global menu
# In theory it is possible to enable global menu in firefox, but there is a bug
# in which the top menubar flashes/flickers: It appears, disappears multiple
# times per second.
# Offered solutions does not seem to have any effect.
# Ref. 
#   https://www.reddit.com/r/firefox/comments/1kb52tp/fix_for_firefox_138_glitch_with_kde_plasma_global/
#
# Still, to enable with about:config, change the following settings to true:

#widget.gtk.global-menu.enabled
#widget.gtk.native-context-menus
#widget.gtk.global-menu.wayland.enabled



## Add some common aliases to $HOME/.bash_aliases
# use ctrl+v to paste something piped to xclip
q="# make xclip use XA_CLIPBOARD per default\n"
q="${q}alias xclip='xclip -selection clipboard'"
if ! grep -q "$(printf "$q" | tail -n 1)" "$HOME/.bash_aliases"; then
  printf "\n$q\n" >> "$HOME/.bash_aliases"
fi
# use legacy SCP protocol
q="# add the default -O (legacy) option to scp\n"
q="${q}alias scp='scp -O'"
if ! grep -q "$(printf "$q" | tail -n 1)" "$HOME/.bash_aliases"; then
  printf "\n$q\n" >> "$HOME/.bash_aliases"
fi

# check if reboot (or log off/on) is required
if [ $REBOOT = 1 ]; then
  printf ">>    PLEASE REBOOT SYSTEM NOW ...\n"
fi
exit 0
