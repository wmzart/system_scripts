#!/bin/sh

# This script basically modifies the ubuntu mate theme to cupertino and makes
# sure it uses the Ambiant-MATE-Dark which was the default ubuntu unity theme
# in 20.04 and places it on top of the cupertino style.
#
# Furthermore it changes the wallpaper of the desktop to the hardy birdy. And
# it changes the control center icon to the round gears, which should help to
# better recognize it. It fixes the VPN icons with the lock, the list view in 
# caja to not show the ugly wide horizontal bar around a selection. Fixes
# the barely visible text cursor when renaming in caja for compact view,
# increases the size of the GTK expander triangle which is too small, places the
# dock on the left using the Plank theme and removes the clock from plank dock,
# since there is already a clock at the top of the desktop.
#
#
# As with all scripts in this series, it should be possible to execute multiple
# times, without modifying an existing setup/installation.
#
# License: MIT
# Author: Marc Nijdam (2025)

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done


## verify environment variables
if [ -z "${HOME#/home/}" ]; then
  echo "unable to proceed with unspecified user: \$${HOME#/home/} undefined"
  exit 0
fi

# URL where to download hardy wallpaper, if wallpaper is not located on USB
REMOTE_SERVER="https://dl.auditeon.com/pub/install/"
WALLPAPER_ARCHIVE="hardy_background.svg.zip"
WALLPAPER_NAME="hardy_wallpaper.svg"

# Alternative icon for Control Center. Make sure to include the exact file name
# of the png file in the name of the zip archive.
CTRL_CENTER_ICON="gnome-control-center.png.zip"

set_ambiant_mate_dark () {
  # clone Ambiant-MATE-Dark which was the default ubuntu unity theme in 20.04
  printf ">>    clone ubuntu unity 20.04 theme, Ambiant-MATE-Dark...\n"
  if [ ! -d ~/Maintenance/apps/ubuntu-mate-themes ]; then
    mkdir -p ~/Maintenance/apps
    cd ~/Maintenance/apps
    git clone https://github.com/flexiondotorg/ubuntu-mate-themes.git
  fi
  # Note that there is an issue with the GTK expander triangle which is too small. To fix,
  # change the GtkToolItemGroup-expander-size and GtkTreeView-expander-size to the minimum size of 16
  # in ../usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/gtk-widgets.css
  if grep -q "GtkToolItemGroup-expander-size: 11;" ~/Maintenance/apps/ubuntu-mate-themes/usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/gtk-widgets.css; then
    sed -i 's/\([[:blank:]]*-GtkToolItemGroup-expander-size:[[:blank:]]*\)[0-9]*/\116/' ~/Maintenance/apps/ubuntu-mate-themes/usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/gtk-widgets.css
  fi
  if grep -q "GtkTreeView-expander-size: 8;" ~/Maintenance/apps/ubuntu-mate-themes/usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/gtk-widgets.css; then
    sed -i 's/\([[:blank:]]*-GtkTreeView-expander-size:[[:blank:]]*\)[0-9]*/\116/' ~/Maintenance/apps/ubuntu-mate-themes/usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/gtk-widgets.css
  fi
  if [ ! -d /usr/share/themes/Ambiant-MATE-Dark ]; then
    # copy Ambiant-MATE-Dark and Ambiant-MATE theme and icons to /usr/share/themes/ resp. /usr/share/icons/
    sudo cp -r ~/Maintenance/apps/ubuntu-mate-themes/usr/share/themes/Ambiant-MATE-Dark /usr/share/themes/
    sudo cp -r ~/Maintenance/apps/ubuntu-mate-themes/usr/share/icons/Ambiant-MATE /usr/share/icons/
  fi

  # Customization: settings to select icons from Ambiant-MATE
  gsettings set org.mate.interface menus-have-icons false
  gsettings set org.mate.interface gtk-theme 'Ambiant-MATE-Dark'
  gsettings set org.ayatana.indicator.a11y gtk-theme 'Ambiant-MATE-Dark'
  gsettings set org.mate.interface gtk-color-scheme unset
  gsettings set org.mate.Marco.general theme 'Ambiant-MATE-Dark'
  gsettings set org.gnome.desktop.interface color-scheme 'default'
  gsettings set org.mate.interface icon-theme 'Ambiant-MATE'
  gsettings set org.ayatana.indicator.a11y icon-theme 'Ambiant-MATE'
  gsettings set org.mate.interface font-name 'Ubuntu Sans Bold 12'
  gsettings set org.mate.interface document-font-name 'Ubuntu Sans Medium 12'
  gsettings set org.mate.caja.desktop font 'Ubuntu Sans Medium 12'
  gsettings set org.mate.Marco.general titlebar-font 'Ubuntu Sans Medium 12'
  gsettings set org.mate.interface monospace-font-name 'Ubuntu Mono 13'
  printf "Done.\n"
  # fix barely visible text cursor when renaming in caja for compact view
  if ! grep -q "when renaming visible in Compact View" /usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/apps/mate-applications.css; then
    printf ">>    fix barely visible text cursor when renaming in caja for compact view...\n"
    line=$(grep -n '* Mate-Panel *' /usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/apps/mate-applications.css | tail -n1 | cut -f1 -d:)
    line=$(( line -1 ))
    q="\/\* make barely visible cursor when renaming visible in Compact View \*\/\n"
    q="${q}.caja-navigation-window widget.view widget.entry,\n"
    q="${q}.caja-desktop-window widget.view widget.entry {\n"
    q="${q}  background: @dark_bg_color;\n"
    q="${q}  color: @dark_fg_color;\n"
    q="${q}  border-color: #181818; }\n"
    q="${q}.caja-navigation-window widget.view widget.entry:selected,\n"
    q="${q}.caja-desktop-window widget.view widget.entry:selected {\n"
    q="${q}  background: #87A556;\n"
    q="${q}  color: #FFFFFF; }\n"
    sudo sed -i "$line i $q" /usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/apps/mate-applications.css
    printf "Done.\n"
  fi
  # fix barely visible cursor for caja list view
  if ! grep -q "when renaming visible in List View" /usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/apps/mate-applications.css; then
    printf ">>    fix barely visible cursor when renaming visible in List View...\n"
    q="\/\* make barely visible cursor when renaming visible in List View \*\/\n"
    q="${q}\/\* EelEditableLabel (icon labels) \*\/\n"
    q="${q}.caja-desktop.view entry,\n"
    q="${q}.caja-desktop.view entry:focus,\n"
    q="${q}.caja-desktop.view entry:backdrop,\n"
    q="${q}.caja-navigation-window .view entry,\n"
    q="${q}.caja-navigation-window .view entry:active,\n"
    q="${q}.caja-navigation-window .view entry:focus,\n"
    q="${q}.caja-navigation-window .view entry:backdrop {\n"
    q="${q}    border-image: none;\n"
    q="${q}    border-style: solid;\n"
    q="${q}    border-width: 1px;\n"
    q="${q}    border-color: #000000;\n"
    q="${q}    border-radius: 3px;\n"
    q="${q}    color: @dark_fg_color;\n"
    q="${q}    text-shadow: none;\n"
    q="${q}    background-image: -gtk-gradient(linear,\n"
    q="${q}                                    left top, left bottom,\n"
    q="${q}                                    from       (shade(@dark_bg_color, 0.86)),\n"
    q="${q}                                    color-stop (0.15, shade(@dark_bg_color, 0.96)),\n"
    q="${q}                                    color-stop (0.50, shade(@dark_bg_color, 0.98)),\n"
    q="${q}                                    to         (shade(@dark_bg_color, 1.00)));\n"
    q="${q}}"
    sudo sed -i "/^\/\* EelEditableLabel/,/^\}/c$q" /usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/apps/mate-applications.css
    printf "Done.\n"
  fi
  ## fix: caja -> hovering mouse over files names ... do not highlight them with a horizontal bar
  if ! grep -q "do not highlight a line when hovering in caja" /usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/gtk-widgets.css; then
    printf ">>    do not highlight a line when hovering in caja...\n"
    q="\/\* do not highlight a line when hovering in caja \*\/\n"
    q="${q}/*.view text selection:hover,*/\n"
    q="${q}/*.view:hover {*/\n"
    q="${q}/*       background-color: shade (@theme_selected_bg_color, 1.55);*/\n"
    q="${q}/*       color: shade (@theme_selected_bg_color, 0.35);*/\n"
    q="${q}/*}*/"
    sudo sed -i "/^.view text selection:hover,/,/^\}/c$q" /usr/share/themes/Ambiant-MATE-Dark/gtk-3.0/gtk-widgets.css
    printf "Done.\n"
  fi
  ## Fix: missing padlock indicator for active vpn network connection (Wifi, Ethernet, gsm etc.)
  #   sudo strace -f -t -e trace=file -p $(pidof mate-indicator-applet-complete) 2>&1 grep status
  #   If this does not work, try to logout on login?
  # ref. https://ubuntu-mate.community/t/18-04-vpn-icon-not-ok/16624/5
  if [ ! -f /usr/share/icons/Ambiant-MATE/status/22/nm-signal-00-secure.svg ]; then
    VPN_ICONS="missing_nm_wifi_icons.tar.bz2"
    [ -f "$HOME/Downloads/${VPN_ICONS}" ] && rm "$HOME/Downloads/${VPN_ICONS}"
    wget -q -O "$HOME/Downloads/${VPN_ICONS}" "${REMOTE_SERVER%/}/${VPN_ICONS}" 2>&1
    if [ "$?" = 0 ]; then    
      printf ">>    Adding missing wifi padlock vpn icons for theme Ambiant-MATE... "
      sudo tar xjf "$HOME/Downloads/${VPN_ICONS}" -C /usr/share/icons/Ambiant-MATE/status/
      sudo tar xjf "$HOME/Downloads/${VPN_ICONS}" -C /usr/share/icons/Ambiant-MATE/status@2/
      sudo gtk-update-icon-cache /usr/share/icons/Ambiant-MATE
      rm "$HOME/Downloads/${VPN_ICONS}"
      printf "done.\n"
    fi
  else
    printf "wifi padlock vpn icons already present for theme Ambiant-MATE. Skipping.\n"
  fi
  return 0
}

###############################
##
## >>>>> code entry below <<<<<


echo ">>>> ATTENTION: ABOUT TO CHANGE USER-INTERFACE INTO UBUNTU UNITY. READ CAREFULLY!"
if ! command -v mate-tweak 2>&1 >/dev/null; then
  printf "unable to find mate-tweak. Aborting.\n"
  exit 1
fi
if ! command -v git 2>&1 >/dev/null; then
  printf "unable to find git. Please install with menu option f. Aborting.\n"
  exit 1
fi


startsudo
# install dependencies for global menu with for example pluma and gimp
sudo apt-get update && sudo apt-get install appmenu-gtk2-module appmenu-gtk3-module

# for unity-style menus, we first select apple-like cupertino layout, then tweak to resemble unity
# Using workaround for errors with:
#   the panel encountered a problem while loading "AppmenuAppletfactory::AppmenuApplet"
# is to temporary use another theme without global menu and then switching to cupertino.
# References:
#  https://ubuntu-mate.community/t/latest-updates-to-22-04-2-two-different-problems/26636/19
#  https://ubuntu-mate.community/t/custom-layout-based-on-cuptertino-problems-with-plank-and-applets/25438
#  https://forums.linuxmint.com/viewtopic.php?t=327379
#  https://ubuntu-mate.community/t/remove-appmenu-help/22290/7
#  http://www.webupd8.org/2017/02/alternative-global-menu-for-mate-and.html
#  File eleven is defined here: /usr/share/mate-panel/layouts/
#  there is the eleven.layout, which contains an applet-iid referencing
#  the file following file in /usr/share/mate-panel/applets/
#
#    org/vala-panel.appmenu.mate-panel-applet
#
#  which contain a similar reference:
#
#   [Applet Factory]
#   Id=AppmenuAppletFactory
#   Location=/usr/lib/x86_64-linux-gnu/mate-panel/libappmenu-mate.so
if [ "$(mate-tweak --get-layout | grep "Current layout")" != "Current layout: eleven" ]; then
  printf ">>    enabling osx theme to get global menu...\n"
  printf ">>    temporary switching to user layout mutiny to fix a system error..."
  mate-tweak --layout mutiny
  printf ">>    waiting 10 seconds for finalization..."
  sleep 10
  mate-tweak --layout eleven
  printf ">>    waiting another 10 seconds for finalization..."
  sleep 10
  printf "done.\n"
  # make sure that the top panel comes back in case it disappears
  printf ">>    resetting top-panel... "
  mate-panel --reset
  sleep 5
  printf "done.\n"
fi


# set desktop background to hardy_wallpaper
# see also: https://ubuntu-mate.community/t/how-to-change-login-screen-background/216/6
if ! gsettings get org.mate.background picture-filename | grep -q "/usr/share/backgrounds/${WALLPAPER_NAME}"; then
  get_mounted_drive "${WALLPAPER_ARCHIVE}" "quiet"
  if [ "$?" = 0 ]; then 
    cp "${MNTF%/}/${WALLPAPER_ARCHIVE}" "$HOME/Downloads/"
  else 
    wget -O "$HOME/Downloads/${WALLPAPER_ARCHIVE}" "${REMOTE_SERVER%/}/${WALLPAPER_ARCHIVE}"
  fi
  if [ -f "$HOME/Downloads/${WALLPAPER_ARCHIVE}" ]; then
    printf ">>    changing desktop background to hardy birdy...\n"
    cd ~/Downloads
    unzip "${WALLPAPER_ARCHIVE}"
    sudo mv "${WALLPAPER_NAME}" /usr/share/backgrounds/
    rm "${WALLPAPER_ARCHIVE}" 
    gsettings set org.mate.background picture-filename "/usr/share/backgrounds/${WALLPAPER_NAME}"
    sleep 0.5
    printf "Done.\n"
  else
    printf "No alternative desktop background image can be found. Unable to change.\n"
  fi
fi


# getting a dock on the left using the Plank theme
# Consider placing themes in /usr/share/plank/themes/ instead: https://www.linuxuprising.com/2019/12/a-guide-to-using-plank-dock-on-linux.html
printf ">>    getting a dock on the left using the Plank theme...\n"
if [ ! -d ~/Maintenance/apps/plankthemes ]; then
  mkdir -p ~/Maintenance/apps
  cd ~/Maintenance/apps
  git clone https://github.com/erikdubois/plankthemes.git
fi
if [ ! -d /usr/share/plank/themes/TransPanel ]; then
  sudo cp -R ~/Maintenance/apps/plankthemes/TransPanel /usr/share/plank/themes/
  # make background a bit darker for dock
fi
if grep -q "FillEndColor=30;;30;;30;;175" /usr/share/plank/themes/TransPanel/dock.theme; then
  sudo sed -i 's/FillEndColor=30;;30;;30;;175/FillEndColor=20;;20;;20;;175/g' /usr/share/plank/themes/TransPanel/dock.theme
fi
gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ theme 'TransPanel'
gsettings set org.mate.hud enabled true
gsettings set org.mate.session.required-components dock 'plank'
# copy overlay files to .config/plank/dock1/launchers/
# https://github.com/ubuntu-mate/ubuntu-mate-settings/blob/master/usr/lib/ubuntu-mate/ubuntu-mate-settings-overlay
gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ theme 'TransPanel'
gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ position 'left'
gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ hide-mode 'none'
gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ icon-size 24
gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ zoom-enabled false
gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ alignment 'fill'
gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ items-alignment 'start'
printf "Done.\n"
sleep 0.5


## clone Ambiant-MATE-Dark which was the default ubuntu unity theme in 20.04
set_ambiant_mate_dark

## Let only the Alt key reveal (underline) the accelerator key for a mnemonic instead of Alt + F10
## show permantently underscore: https://unix.stackexchange.com/questions/212470/enabling-alt-hotkeys-for-buttons-in-gnome
# printf '%s\n' "gtk-auto-mnemonic = 0" > ~/.gtkrc-2.0
# org.gnome.desktop.interface menubar-accel "Alt": Keyboard shortcut to open the menu bars. (Default settings: "F10")
# gsettings set org.gnome.desktop.interface menubar-accel "Alt"
# org.mate.interface automatic-mnemonics: "Only show mnemonics on when the Alt key is pressed" (Default setting: true)
# gsettings set org.mate.interface automatic-mnemonics false


## change dock mate control center icon. The default squarish icon is not very destinctive from other square icons
if ! grep -q -e '^Icon=preferences-desktop2' /usr/share/applications/matecc.desktop; then
  wget -O "$HOME/Downloads/${CTRL_CENTER_ICON}" "${REMOTE_SERVER%/}/${CTRL_CENTER_ICON}"
  if [ "$?" = 0 ]; then
    printf ">>    change dock mate control center icon...\n"
    cd ~/Downloads
    unzip "${CTRL_CENTER_ICON}"
    sudo xdg-icon-resource install --novendor --size 128 "${CTRL_CENTER_ICON%.zip}" preferences-desktop2
    rm "${CTRL_CENTER_ICON}" "${CTRL_CENTER_ICON%.zip}"
    sudo sed -i 's/Icon=preferences-desktop/Icon=preferences-desktop2/g' /usr/share/applications/matecc.desktop
    printf "Done.\n"
  else
    printf "Unable to download mate control center icon...\n"
  fi
fi

## mate desktop menu is called brisk. Default window-type 'dash' has full screen. Disable that.
# https://ubuntu-mate.community/t/can-i-change-the-cupertino-brisk-menus-layout/17110
printf ">>    change Cupertino Brisk menu's layout to not be full screen... "
gsettings set com.solus-project.brisk-menu window-type 'classic'
printf "done.\n"
# remove clock from plank dock.
# Please note that the configuration for the presence of dockitems is file
# based, not dconf setting based, so maybe contrary to what expected, the
# following will not work:
#
# gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ dock-items \
# "$(gsettings get net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ dock-items | sed "s/, 'clock.dockitem'//")"
#
# instead just delete the files:
if [ -f "$HOME/.config/plank/dock1/launchers/clock.dockitem" ]; then
  printf ">>    remove clock from plank dock... "
  rm "$HOME/.config/plank/dock1/launchers/clock.dockitem"
  printf "done.\n"
fi
stopsudo
exit 0

