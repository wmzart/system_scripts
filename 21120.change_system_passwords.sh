#!/bin/sh

# This module ask a user for passwords and change them for the following:
#  * luks LVCM disk encryption
#  * system default user
#  * system root user
#  * (optional when installed) dovecot imap user
#
# Setting a fixed password and allowing the user to change it once installation
# is complete is a compromise between ease of use and system safety.
#
# Author: Marc Nijdam, Dec. 2025
# License: MIT

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done

##
# https://superuser.com/questions/431820/how-to-change-pass-phrase-of-full-disk-encryption
echo ">>>> ATTENTION: ABOUT TO CHANGE PASSWORDS. READ CAREFULLY!"
echo ">> 1. Changing passphrase for luks disc encryption <<"
startsudo
crdev=$(sudo blkid | awk -F':' '/crypto_LUKS/{ print $1 }')
if [ -z $crdev ]; then
  echo "Unable to find encrypted disk. Aborting..."
  exit 1
fi
echo ">>    Please make sure only one slot is listed below:"
sudo cryptsetup luksDump ${crdev} | grep luks2
echo ">>    Add a new passphrase for the LVM disk encryption:" 
echo ">>    (Please note: existing passphrase was: ubuntu)"
sudo cryptsetup luksAddKey ${crdev}
echo ">>    Please make sure now two slots are listed below:"
sudo cryptsetup luksDump ${crdev} | grep luks2
echo ">>    Please remove the initial passphrase (ubuntu) now:"
sudo cryptsetup luksRemoveKey ${crdev}
echo ">> 2. change password of user root: <<"
echo ">>    (Please note: existing password was: ubuntu)"
sudo passwd root
echo ">> 3. change password of user ${HOME#/home/}: <<"
passwd
# only ask for password if dovecot is installed
if [ -f /etc/dovecot/users ]; then
  printf ">> 4. please enter a new password for dovecot imap user (Press ENTER to skip) ${HOME#/home/}: "
  read dovecot_pw
  if [ ! -z ${dovecot_pw} ]; then
    # remove user ${HOME#/home/} from users file and then add again
    other_users=$(grep -v "${HOME#/home/}@${DDOMAIN}")
    echo "$other_users" | sudo tee /etc/dovecot/users
    # create the user name in the user file
    lsha512=$(sudo doveadm pw -s SHA512-CRYPT -p ${dovecot_pw})
    echo "${HOME#/home/}@${DDOMAIN}:${lsha512#*\}}:$(id -u ${DUSRGRP}):$(getent group ${DUSRGRP} | cut -d: -f3)::/home/${DUSRGRP}/${HOME#/home/}@${DDOMAIN}/::" | sudo tee -a /etc/dovecot/users
    printf "Password for dovecot imap user ${HOME#/home/} changed to ${dovecot_pw}\n"
  else
    printf "Skip changing password for dovecot imap user ${HOME#/home/}\n"
  fi
fi
stopsudo
exit 0
