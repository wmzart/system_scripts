#!/bin/sh

# target user is default user, (password will be changed at a later moment).
TU="$(whoami)"

# This script helps to backup/restore and configure a system. It was developed
# to save time and especially make installations consistent.
# With the fantastic Ubuntu Mate distribution which supports a user interface
# similar to Mac OS (Cupertino), there were some issues which required
# modification to system files and configurations to solve.
# And last but not least, the reason why this all started was to optimize the
# default touchpad configuration in such a way that the touchpad (of a Lenovo
# Carbon X1 with three physical buttons), directly after the new operating
# system installation would be finished and directly after the very first login,
# change mainly the scroll direction to 'natural' and disable the option mouse
# clicks with touchpad.
# Because changing mouse settings requires gsettings commands. It is necessary
# for the user to be logged in into a graphical user interface and preferrably
# needs to be done at the very first login, automatically without requiring the
# user to start a script. This can be done at least by using the users'
# ~/.profile file, in which an entry is written during the installation of the
# operating system. Ubuntu provides a way to modify an installation by writing
# an autoinstall.yaml file and integrate this in the installation image.
# 
# This script works in conjunction with a subiquity automatic autoinstall.yaml
# installation, which makes sure that this script is run right after the very
# first time the user logs on. Details how to configure and use an
# autoinstall.yaml file can be found on the internet.
#
# As written above, beyond the initial touchpad configuration change, this
# post-install script can help to configure/install the system mainly with
# following features:
#
#   * Disables snap
#   * Activates a ubuntu unity desktop environment, fixing many issues
#   * Installs further practical software
#   * Easy method to export user-profile backup
#   * Easy method to import user-profile backup
#   * Perform complex installations like a read-only dovecat maildir
#   * Providing file icons in caja for freecad files
#   * Fix an xorg issue where it is impossible to click at the top of the screen
#   * etc.
#
# Setup:
# The post-install.sh script depends for the installation on further modules.
# To make it work, provide a list of these modules in a file called:
#
#   post_install_modules_list.sh
#
# This file and all modules are automatically downloaded if it is not present in
# the same directory as where post-install.sh resides, from the following
# domain:
#   https://dl.auditeon.com/pub/install/

MODLIST='https://dl.auditeon.com/pub/install/post_install_modules_list.sh'

# Each module will be shown as a specific menu option.
#
# The post_install_modules_list.csv file contains a flat list of all modules
# which can be used in this tool. The format of this .csv file is the following:
#
#   "SHORTCUT_KEY";"NNNNN.MODULE_NAME.sh";"MENU_ENTRY_TEXT"
#
# where NNNNN.MODULE_NAME.sh refers to the modules name as provided in the same
# directory where post_install_modules_list.csv resides and MENU_ENTRY_TEXT
# contains the text as being displayed to the user and SHORTCUT_KEY the key as
# being provided as an option for the user to select that module.
# NNN represents a sequential number, allowing for multiple modules to have the
# same name but with different sequential number.
#
# If NNNNN.MODULE_NAME.sh is given with an empty MENU_ENTRY_TEXT, the module
# will be not shown in the menu, but can be used to invoke from within another
# module. Also, if NNNNN < 10, then it will be incorporated from within the
# different modules using the source command (see man bash) and can then be
# invoked as a function or used to reference a defined variable.
#
# Author: Marc Nijdam, Dec. 2025
# License: MIT


# Touchpad settings to disable special meanings of any area are device dependent
# like:
#
# for x1 carbon Gen 4 TPDEV would be:
#   SynPS/2 Synaptics TouchPad
#
# for x1 carbon Gen 11 TPDEV would be:
#   ELAN067C:00 04F3:31F9 Touchpad
#
# Get the touchpad hardware ID
TP_STR1='TPDEV="$(xinput list --name-only | grep -i touchpad)"'
# Disable any area clicks for the touchpad
TP_STR2='xinput --set-button-map "${TPDEV}" 1 1 1 4 5 6 7'


# play a note through the laptop speaker
# $1: frequency in Hz
# $2: duration in s (non-integer values like 0.1 or 0.5 are also possible)
beepr() {
  ( \speaker-test -f $1 -t sine )&
  pid=$!
  \sleep ${2}s
  \kill -9 $pid
}


# $1: username
set_touchpad () {
  ## configure trackpad and mouse
  gsettings set org.mate.peripherals-mouse middle-button-enabled false
  gsettings set org.mate.peripherals-mouse middle-button-enabled false
  gsettings set org.mate.interface gtk-enable-primary-paste false
  # Natural scrolling true
  gsettings set org.mate.peripherals-touchpad natural-scroll true
  # Vertical edge scrolling disable
  gsettings set org.mate.peripherals-touchpad vertical-edge-scrolling false
  # Enable horizontal and vertical two-finger scrolling
  gsettings set org.mate.peripherals-touchpad horizontal-two-finger-scrolling true
  gsettings set org.mate.peripherals-touchpad vertical-two-finger-scrolling true
  # Enable mouse clicks with touchpad disable
  gsettings set org.mate.peripherals-touchpad tap-to-click false
  # Emulate middle button through simultaneous left and right click disable
  gsettings set org.mate.peripherals-mouse middle-button-enabled false
  # Enable middlemouse paste true
  gsettings set org.mate.interface gtk-enable-primary-paste true

  ## Disable unprecise click zones by only allowing one large left-click zone
  # Since Thinkpad has specific left, middle and right buttons, a multiple
  # finger click is potentially error-prone and has no added value.
  # Find the touchpad device with the 'xinput list' command.
  # histchars solves problem with ! character:
  # * https://stackoverflow.com/questions/15011824/how-to-printf-an-exclamation-mark-in-bash
  histchars= 
  q="#!/usr/bin/env bash\n"
  q="${q}# Filename: ~/.xsessionrc\n"
  q="${q}#\n"
  q="${q}# Please note that ~/.xsessionrc is Debian specific.\n"
  q="${q}# From /etc/X11/Xsession the file .xsessionrc is executed.\n"
  q="${q}# There is no need to make it executable: chmod 600 suffices\n"
  q="${q}# Normally this file would be .xinitrc\n"
  q="${q}# But .xinitrc is apparently not sourced in my setup.\n"
  q="${q}\n"
  q="${q}## Configure trackpad bottom button press 1, 2 and 3 (left, middle,\n"
  q="${q}# right) to be all the same. This solves the inaccurate clicking\n"
  q="${q}# areas where something unpredictable may happen.\n"
  q="${q}# To revert this setting, use:\n"
  q="${q}# xinput --set-button-map \"..................... Touchpad\" 1 2 3 4 5 6 7\n"
  q="${q}${TP_STR1}\n"
  q="${q}${TP_STR2}\n"
  q="${q}# check with xinput get-button-map id (9)"
  printf "${q}\n" > "/home/$1/.xsessionrc"
  unset histchars

  # Using subiquity and an autoinstall.yaml file, an entry is written in the
  # following manner  (Where USER refers to the target user.)
  #
  # 1. as root at the section late-commands:
  #   printf "\n# configure touchpad\n[ -f /home/USER/install/post-install.sh ] && sh /home/USER/install/post-install.sh &\n" >> /target/etc/skel/.profile
  #
  # 2. as root at the section user-data (This is executed before the user logs in)
  #   - wget -O /home/USER/install/post-install.sh "https://www.somewhere.com/post-install.sh"
  #   - chmod +x /home/USER/install/post-install.sh
  #   - chown -R USER:USER /home/USER/install/post-install.sh
  #   - sed -i -e '/^# configure touchpad/,+1d' /etc/skel/.profile
  #
  # 3. As soon as the user logs in for the very 1st time, the entry in ~/.profile to start post-install.sh, specifically
  #   [ -f /home/USER/install/post-install.sh ] && sh /home/USER/install/post-install.sh &
  # 
  # 4. During execution of post-install.sh, fully remove entry from users .profile, making sure it only starts once.
  sed -i -e '/^# configure touchpad/,+1d' /home/$1/.profile
}


## config touchpad
touchpad_initial_config () {
  # wait for the user to be logged on
  # 3 seconds is somehow required?
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%
  sleep 0.5
  beepr 440 0.5
  sleep 3
  beepr 554 0.5
  while true; do
    if [ "$(who | awk '{ print $1 }')X" = "${TU}X" ]; then
      ## 2. Mouse and trackpad settings:
      # configure middle trackpad area to not have any special meaning
      # without using the gui, using gsettings
      # Please note, this can be found with: dconf watch /
      beepr 880 0.5
      set_touchpad "${TU}"
      # execute the xinput command manually to make sure it also works the very first time
      eval ${TP_STR1}
      eval ${TP_STR2}
      exit
    else
      beepr 659 0.5
      sleep 1
    fi
  done
}


## checks if a provided line starts with the # character
# $1: line with text, which may or may not start with the # character.
# return 1 if line begins with #, 0 if not
check_if_comment_line () {
  if [ "$(echo $1 | cut -c1-1)" = "#" ]; then
    return 1
  fi
  return 0
}


# return 1 if all provided arguments are empty.
# This is used for the post_install_modules_list.csv file to detect empty,
# comment or lines with only a reference to a file, which can be used as a
# depedency for one or more modules.
check_if_all_empty () {
  ce_cnt=0
  for i in "$@"; do
    if [ $(echo "$i" | wc -c) -le 1  ]; then
      ce_cnt=$(( ce_cnt + 1 ))
    fi
  done
  if [ $# = $ce_cnt ]; then
    return 1
  fi
  return 0  
}


# ==                                ==
# ====                            ====
# ====== CODE ENTRY POINT BELOW ======
# ====                            ====
# ==                                ==


if [ "$(id -u)" = 0 ]; then
  echo "Please do not run as root" > "/home/${TU}/install/install.log"
  exit
fi

# After the initial installation of ubuntu-mate, using autoinstall.yaml, there
# is a command (placed at the late-commands section) to start this
# post-install.sh script indirectly, by placing it in /target/etc/skel/.profile
# (At that time with /target as prefix.)
# Once the user has been created, in the autoinstall.yaml user-data section, the
# command is removed again from /etc/skel/.profile
# At this time, the command is also present in /home/${TU}/.profile and once the
# user logs in, the command to start this post-install.sh script is executed at
# a moment when also the graphical user interface is active to accept gsettings
# commands. 
# This method is so far the only way to execute a custom shell script with
# gsettings commands at startup, because it is executed automatically right
# after the user has logged in.
# The command to start this post-install.sh script in /home/${TU}/.profile 
# will only be available if it has not been executed before. Once started, this
# script at the function touchpad_initial_config will remove the command from
# /home/${TU}/.profile to make sure it will not execute another time.
# There is one small caveat. The very first time, for reasons not fully
# understood, the user should wait about 30 seconds before entering his password
# in the login field. Otherwise the script will not be executed automatically.
# (Which can still be done manually).
# The script will play three specific notes to indicate that the touchpad
# settings have been completed succesfully. This is when the first and the last
# note are at an octave interval.
if grep -q "^# configure touchpad" "/home/${TU}/.profile"; then
  touchpad_initial_config
  exit
fi
 

## download list of modules
if [ ! -f $(basename "$MODLIST") ]; then
  wget "$MODLIST"
  echo "current path: $(dirname "$0")"
  echo "downloading $MODLIST" 
fi


## build user menu using a list of modules
PRE_OPT=0
ESS_OPT=0
OPT_OPT=0
HORL="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
MNU="==== (pre)post-installation options ====\n"
FMNU=""

# read csv line by line, having three columns with separation character ";"
while IFS=';' read -r KEY SRC INF; do
  # strip blank characters
  KEY="$(echo "${KEY}" | awk '{$1=$1;print}' | sed -e 's/^"//' -e 's/"$//')"
  SRC="$(echo "${SRC}" | awk '{$1=$1;print}' | sed -e 's/^"//' -e 's/"$//')"
  INF="$(echo "${INF}" | awk '{$1=$1;print}' | sed -e 's/^"//' -e 's/"$//')"

  # skip comment line
  check_if_comment_line "${KEY}"
  if [ "$?" != 0 ]; then
    continue
  fi

  check_if_all_empty "${KEY}" "${INF}"
  if [ "$?" != 0 ]; then
    check_if_all_empty "${SRC}"
      if [ "$?" != 0 ]; then
        continue
      else
        if [ ! -f "$SRC" ]; then
          # file without menu is given: $KEY
          echo "...importing module $SRC"
          wget -q "$(dirname "${MODLIST}")/$SRC"
          chmod +x "$SRC"
        fi
        continue
      fi
  fi
  
  CAT=$(expr "$(echo ${SRC} | tr -dc '0-9')" + 0)
  case 1 in
    $(($CAT<=9999)))
      if [ "$PRE_OPT" != "1" ]; then
        MNU="${MNU}${HORL}\n"
        MNU="${MNU} Pre-installation options:\n"
        PRE_OPT=1
      fi
      # pre-install options
      MNU="${MNU}  ${KEY}. ${INF}\n"
      FMNU="${FMNU}${KEY}@$SRC\n"
      if [ ! -f "$SRC" ]; then
        echo "...importing module $SRC"
        wget -q "$(dirname "${MODLIST}")/$SRC"
        chmod +x "$SRC"
      fi
      ;;
    $(($CAT<=19999)))
      if [ "$ESS_OPT" != "1" ]; then
        MNU="${MNU}${HORL}\n"
        MNU="${MNU} Post-installation essential steps:\n"
        ESS_OPT=1
      fi
      # essential options
      MNU="${MNU}  ${KEY}. ${INF}\n"
      FMNU="${FMNU}${KEY}@$SRC\n"
      if [ ! -f "$SRC" ]; then
        echo "...importing module $SRC"
        wget -q "$(dirname "${MODLIST}")/$SRC"
        chmod +x "$SRC"
      fi
      ;;
    $(($CAT<=29999)))
      if [ "$OPT_OPT" != "1" ]; then
        MNU="${MNU}${HORL}\n"
        MNU="${MNU} Post-installation optional steps:\n"
        OPT_OPT=1
      fi
      # optional options
      MNU="${MNU}  ${KEY}. ${INF}\n"
      FMNU="${FMNU}${KEY}@$SRC\n"
      if [ ! -f "$SRC" ]; then
        echo "...importing module $SRC"
        wget -q "$(dirname "${MODLIST}")/$SRC"
        chmod +x "$SRC"
      fi
      ;;
    *)
      # unknown options
      echo "UNKOWN OPTION ${KEY}. ${INF}"
      # show_error
      ;;
  esac
done < "$(basename "$MODLIST")"


## get user selection
MNU="${MNU}${HORL}\n  q. quit\n"
while : ; do
  printf "\n${MNU}"
  echo -n "Select option: "
  while read line; do
    if [ ! -z $(echo $line | egrep "^[0-9a-zX]+$") ]; then
      if [ "$line" = "q" ]; then
        exit
      fi
      module=$(printf "${FMNU}" | awk -v var="^${line}" 'match($0, var) {print substr($0, 3)}')
      if [ ! -z "${module}" ]; then
        /bin/sh "${module}"
        break
      else
        echo -n "Unknown option selected. Please try again: "
      fi
    fi
  done
done

exit
