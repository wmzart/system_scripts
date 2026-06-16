#!/bin/sh

# This module will restore archives with special purpose files
# which were created earlier.
#
# At the moment these are:
#   vuescan license file
#   rar license file
#   bash_aliases file
#
# Author: Marc Nijdam, 2026
# License: MIT
#

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done


## Restore rar license file
# $1: license file (including path) to install.
# Place the license file either on the main directory of the USB disk.
# The archive should contain only one file: rarreg.key and be called:
#   rarreg.license.tar.bz2
restore_rar_license () {
  if [ -f /etc/rarreg.key -a -f /usr/local/bin/rar -a -f /usr/local/bin/unrar ]; then
    echo ">>    rar and license key already installed..."
    return 0
  fi
  # extracting license and move to /etc
  TMP_DIR=$(mktemp -d)
  trap rm_tmp INT
  cd $TMP_DIR
  if [ ! -f "/etc/rarreg.key" ]; then
    echo ">>    Installing rar license..."
    cp "$1" "${TMP_DIR%/}/"
    tar xjf "$(basename "$1")"
    sudo mv "${TMP_DIR%/}/$(tar jtf "$(basename "$1")")" /etc/
  fi
  echo ">>    Done."
  rm_tmp
  trap - INT
}


## Restore vuescan license file
# $1: license file (including path) to install.
# The archive on USB stick should contain one file: .vuescanrc and be called:
#   vuescan.license.tar.bz2
restore_vuescan_license () {
  if [ -f "$HOME/.vuescanrc" -a -f /usr/bin/vuescan ]; then
    echo ">>    vuescan and license key already installed..."
    return 0
  fi
  # extracting license and move to $HOME
  TMP_DIR=$(mktemp -d)
  trap rm_tmp INT
  cd $TMP_DIR
  if [ ! -f "$HOME/.vuescanrc" ]; then
    echo ">>    Installing vuescan license"
    cp "$1" "${TMP_DIR%/}/"
    tar xjf "$(basename "$1")"
    mv "${TMP_DIR%/}/$(tar jtf "$(basename "$1")")" "${HOME}"
  fi
  echo "Done."
  rm_tmp
  trap - INT
}


## Restore bash_aliases file
# $1: bash_aliases file (including path) to install.
# The archive on USB stick should contain one file: .bash_aliases and be called:
#   bash_aliases.tar.bz2
restore_bash_aliases () {
  if [ -s "$HOME/.bash_aliases" ]; then
    echo ">>    ~/.bash_aliases already exists and not empty... Skipping overwriting..."
    return 0
  fi
  # In all other cases create or overwrite
  # extracting bash_aliases and move to $HOME
  TMP_DIR=$(mktemp -d)
  trap rm_tmp INT
  cd $TMP_DIR
  echo ">>    Restoring bash_aliases file to ~/.bash_aliases"
  cp "$1" "${TMP_DIR%/}/"
  tar xjf "$(basename "$1")"
  mv "${TMP_DIR%/}/$(tar jtf "$(basename "$1")")" "${HOME}"
  echo "Done."
  rm_tmp
  trap - INT
}


##
restore_archives () {
  echo ">>>> ATTENTION: ABOUT TO RESTORE FILES PREVIOUSLY ARCHIVED. READ CAREFULLY!"
  echo ">>    rar + vuescan license and bash_aliases."
  startsudo
  # install winrar
  get_mounted_drive
  if [ "$?" != 0 ]; then
    echo "No USB drive found. Skipping"
  else
    # restore if rarreg.license.tar.bz2 is present on USB drive
    if [ -f "${MNTF%/}/rarreg.license.tar.bz2" ]; then
      restore_rar_license "${MNTF%/}/rarreg.license.tar.bz2"
    fi
  fi
  # restore vuescan license
  get_mounted_drive
  if [ "$?" != 0 ]; then
    echo "No USB drive found. Skipping"
  else  
    # restore if vuescan.license.tar.bz2 is present on USB drive
    if [ -f "${MNTF%/}/vuescan.license.tar.bz2" ]; then
      restore_vuescan_license "${MNTF%/}/vuescan.license.tar.bz2"
    fi
  fi
  # restore bash_aliases
  get_mounted_drive
  if [ "$?" != 0 ]; then
    echo "No USB drive found. Skipping"
  else  
    # restore if bash_aliases.tar.bz2 is present on USB drive
    if [ -f "${MNTF%/}/bash_aliases.tar.bz2" ]; then
      restore_bash_aliases "${MNTF%/}/bash_aliases.tar.bz2"
    fi
  fi 

  stopsudo
  return 0
}

###############################
##
## >>>>> code entry below <<<<<

restore_archives
