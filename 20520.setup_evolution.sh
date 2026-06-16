#!/bin/sh

# This script installs the evolution mail client and configures it using a
# backup of a previous installation.
#
# It uses the file defined in EVO_ARCHIVE ("evolution-backup-") for restoring
# the complete setup of evolution.
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

startsudo
sudo apt update
sudo apt-get -y install evolution
sudo apt-get -y install evolution-ews
# Prevent client side decoration with evolution:
gsettings set org.gnome.evolution.shell use-header-bar false
# Show menubar evolution:
gsettings set org.gnome.evolution.shell menubar-visible true
# configure the option to mark messages to be read after 0.3 seconds
gsettings set org.gnome.evolution.mail mark-seen-timeout 100
# configure the option to disable sound when a new message arrives (fixes crash notifier?)
gsettings set org.gnome.evolution.plugin.mail-notification notify-sound-enabled false
# improve search feature in evolution
gsettings set org.gnome.evolution.mail global-view-search false
# Unset colors provided in HTML mails in message preview
gsettings set org.gnome.evolution.mail preview-unset-html-colors true
# always show full e-mail address
gsettings set org.gnome.evolution.addressbook completion-show-address true
printf ">>    configure evolution mail from backup...\n"
evolution --force-shutdown > /dev/null 2>&1

# Retrieve MNTF for mountpoint and BSFN for basename, based on the file
# "evolution-backup-", which should be present in the main directory of the USB
# drive.
get_mounted_drive "${EVO_ARCHIVE}*" || { echo "Please make sure to put this file on the root directory from a USB-drive."; exit 1; }
# EVO_ARCHIVE is a partial name. BSFN is the first name which matches
printf ">>>> ATTENTION: archive ${BSFN} found.\n"
printf "Do you wish to use this for evolution mail (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then 
  tar xzf "${MNTF%/}/${BSFN}" -C ~/
  printf "Done.\n"
  echo "You may now start evolution and proceed with entering passwords."
fi
  
# If you encounter the following error:
#  did not find extension DRI_Mesa version 1
# fix by installing:
# sudo apt-get install libgl1-mesa-dri:amd64 -y
stopsudo
exit 0
