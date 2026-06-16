#!/bin/sh

# license: gpl
# This script writes a firefox profile from a previously archived file back.
#
# License: MIT
# Author: Marc Nijdam (2025)

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done


# test if firefox is running
if ps ax -ocomm | grep -q "[f]irefox"; then
  printf ">>    Unable to proceed if firefox is running. Exit firefox and retry. Aborting...\n"
  exit 1
fi

## copy mozilla profile over from archive
# inside archive paths are absolute, like: $HOME/.mozilla
# (created with: tar cvjSf mozilla.profile.tar.bz2 ~/.mozilla)
get_mounted_drive "${MOZ_ARCHIVE}" || { echo "Please make sure to put this file on the root directory of a USB-drive."; exit 1; }
if [ -f "${MNTF%/}/${MOZ_ARCHIVE}" ]; then
  printf ">>>> ATTENTION: archive ${MOZ_ARCHIVE} found.\n"
  printf "Do you wish to replace the ~/.mozilla directory with the contents of the archive? (y/n)? "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    [ -d ~/.mozilla ] && mv ~/.mozilla ~/.mozilla_OLD
    SSIZE=$(stat -c %s "${MNTF%/}/${MOZ_ARCHIVE}")
    CHECKPOINT=$(echo "${SSIZE}/512/20/50*100/55" | bc)
    echo "Estimated: [==================================================]"
    echo -n "Progress:  ["
    tar xjf "${MNTF%/}/${MOZ_ARCHIVE}" --strip-components=2 --checkpoint=${CHECKPOINT} --checkpoint-action=dot -C ~/
    echo "]"
    [ -d ~/.mozilla_OLD ] && rm -Rf ~/.mozilla_OLD
    printf "Done.\n"
    exit 0
  fi
fi
exit 0
