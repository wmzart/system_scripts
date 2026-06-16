#!/bin/sh

# This module sets the systems' hostname
# Author: Marc Nijdam, Dec. 2025
# License: MIT

echo ">>>> ATTENTION: ABOUT TO CHANGE HOSTNAME. READ CAREFULLY!"
echo ">>    This requires root. Please enter password when asked (hint: ubuntu):"
echo "Current hostname: $(hostname)" 
printf "Please enter a new hostname or enter to abort>"
read new_hostname
if [ ! -z ${new_hostname} ]; then
  if [ "$(hostname)" = "${new_hostname}" ]; then
    printf "No change found. Leaving hostname unchanged\n"
    exit 0
  fi
  sudo hostnamectl set-hostname ${new_hostname}
  printf "Hostname changed\n"
fi
exit 0


