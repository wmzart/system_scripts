#!/bin/sh

# This module prepares a system in such a way that it renders the filesystem
# unusable. This will make it possible for the autoinstaller subiquity
# to (re)create a LVM + LUKS based filesystem on the target disk.
# If this is not done, subiquity will throw an error and an automatic
# installation will not be possible.
#
# References:
#  * https://bugs.launchpad.net/subiquity?field.searchtext=luks+lvm
#  * https://bugs.launchpad.net/ubuntu-desktop-provision/+bug/2069636
#  * https://bugs.launchpad.net/subiquity/+bug/1884715
#
# created by Marc Nijdam, Feb. 2025
#
# license: MIT

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done

## degrade system

MNTF=$(mount | grep "/media/${HOME#/home/}" | head -n 1 | awk '{print $3}')
if [ ! -z "${MNTF}" ]; then
  echo "Please make sure to first unmount any external USB-drive(s)."
  exit 1
fi
printf ">>>> ATTENTION: prepare system for reinstall.\n"
printf ">> Please note that this step destroys your current filesystem and is\n"
printf ">> only required if you are using subiquity for an automatic system\n"
printf ">> installation in a constellation with LVM and LUKS. For more info:\n"
printf ">> https://bugs.launchpad.net/ubuntu-desktop-provision/+bug/2069636\n\n"
printf ">>    found following devices: "
for stor in $(systemctl | grep nvme | sed -n 's/.*\(nvme0n1p*[0-9]\).*/\1/p'); do echo -n " ${stor}"; done
printf "\n"
printf "ARE YOU REALLY SURE TO OVERWRITE YOUR MAIN STORAGE? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  echo ">>    Overwriting your system drive requires root. Please enter password (hint: ubuntu):"
  sudo -v
  for stor in $(systemctl | grep nvme | sed -n 's/.*\(nvme0n1p*[0-9]\).*/\1/p'); do sudo dd if=/dev/zero of=/dev/${stor} bs=8M count=20; done
  # If the above does not work, consider using dd or wipefs:
  #   sudo dd if=/dev/zero of=/dev/nvme0n1 bs=512 count=1
  # or
  #   sudo wipefs --force --all /dev/nvme0n1*
  echo "Done. Please continue with installation via autoinstall USB memory device"
fi

exit 0 
