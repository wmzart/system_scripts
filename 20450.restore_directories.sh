#!/bin/sh

# This module will lorum ipsum

# Using global variable:
#   ...
#
# Author: Marc Nijdam, 2025
# License: MIT
#

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done


echo ">>>> ATTENTION: ABOUT TO RESTORE BACKUP & MAINTENANCE. READ CAREFULLY!"
if ps ax -ocomm | grep -q "[f]irefox"; then
  echo "Please close firefox first."
  exit 1
fi
if ps ax -ocomm | grep -e "[e]volution$"; then
  echo "Please close evolution first."
  exit 1
fi
get_mounted_drive || exit 1
printf ">>>> ATTENTION: drive ${MNTF} found.\n"
printf "Do you wish to restore to ~/backup and ~/Maintenance? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  startsudo
  # 1. rsync to ~/backup
  printf "Copying to ~/backup ... \n"
  sudo rsync -az --delete --info=progress2 --no-i-r --partial "${MNTF%/}/backup/" "$HOME/backup"
  printf "Done\n"
  # 2. rsync to ~/Maintenance
  printf "Copying to ~/Maintenance ... \n"
  sudo rsync -az --delete --info=progress2 --no-i-r --partial "${MNTF%/}/Maintenance/" "$HOME/Maintenance"
  printf "Done\n"
  stopsudo
fi
