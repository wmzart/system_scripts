#!/bin/sh

## Setup ssh by extracting a specified tar.bz2 file from usb drive into ~/.ssh
# The tar.bz2 archive should be created with the 00980.backup_installation.sh
# script or manually with:
#
#   tar cjSf FILENAME -C / home/$(whoami)/.ssh
#
# where FILENAME is filename including the full path on a usb drive
#
# Author: Marc Nijdam, Dec. 2025
# License: MIT


## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done


get_mounted_drive "${SSH_ARCHIVE}" || { echo "Please put a tar.bz2 file with ssh keys on the main directory from a USB-drive."; exit 1; }
printf ">>>> ATTENTION: archive ${SSH_ARCHIVE} found.\n"
printf "Do you wish to replace the ~/.ssh directory with the contents of the archive? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  if [ -d ~/.ssh ]; then
    mv ~/.ssh ~/.ssh_OLD
  fi
  mkdir -p ~/.ssh
  tar xjf "${MNTF%/}/${SSH_ARCHIVE}" -C ~/.ssh/
  # (drwx------)
  chmod 700 ~/.ssh
  # (-rw-------)
  chmod 600 ~/.ssh/id_*
  # (-rw-r--r--)
  chmod 644 ~/.ssh/id_*.pub
  rm -Rf ~/.ssh_OLD
  printf "Done.\n"
fi
exit 0
