#!/bin/sh

# This module updates the apt cache and upgrades accordingly
#
# Author: Marc Nijdam, Dec. 2025
# License: MIT

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done

echo ">>>> ATTENTION: ABOUT TO UPGRADE APT SYSTEM PACKAGES. READ CAREFULLY!"
startsudo
sudo apt-get update
sudo apt-get -y upgrade
stopsudo
return 0



