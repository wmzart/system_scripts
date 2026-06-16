#!/bin/sh

## create new ssh identity and upload for domains on domains.csv from USB drive,
# but only if this file is present. For uploading to one or more domains, the
# script expects that password-less with the existing ssh keys is possible.
#
# Author: Marc Nijdam, Dec. 2025
# License: MIT


## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done

# $1: domain (in the format user@domain)
# $2: key to place in the remote authorized keys file
update_ssh_server_key () {
  printf ">>    Updating $(echo $1 | sed 's/^[^@]*.//') ..."
  echo "$2" | ssh "$1" -o "IdentitiesOnly=yes" -i ~/.ssh_OLD/id_ed25519 'cat >> ~/.ssh/authorized_keys && printf " key copied\n"'
  printf ">>    Removing temporary backup of .ssh ...\n"
  rm -Rf ~/.ssh_OLD
  printf "Done.\n"
}

## READ all lines from the identities file and extract the given ssh domain name
printf ">>>> ATTENTION: CREATING NEW SSH IDENTITY AND UPDATING REMOTE.\n"
printf ">>    Creating temporary backup of .ssh ...\n"
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 600 ~/.ssh/id_*.pub
cp -R ~/.ssh ~/.ssh_OLD
printf ">>    Creating a new identity...\n"
ssh-keygen -t ed25519 -C "$(hostname)"

get_mounted_drive "${SECRETS_FILE}" || { echo "Please put a file with a list of key/value definitions on the main directory of a USB-drive."; exit 1; }
printf ">>>> CHECKING REQUIREMENTS:\n  - File with list of key/value definitions ("${SECRETS_FILE}") found on USB-drive.\n"


# updating ssh on or more ssh server(s)
lookup_field "${SSH_ACCESS_SRV_ID}" "${MNTF%/}/${SECRETS_FILE}" 2
# iterate through a comma separated list with user@domain entries, like:
# "${SSH_ACCESS_SRV_ID}";"USER1@DOMAIN1,USER2@DOMAIN2,USER3@DOMAIN3";""
# where ${SSH_ACCESS_SRV_ID} is defined in 00000.global_variables.sh and used in the file ${SECRETS_FILE}
while : ; do
  SSH_SERVER=$(echo "${RETVAL}" | awk -F ',' '{ print $NF }')
  echo ">>    Updating: $SSH_SERVER"
  echo ">>    Key: $HOME/.ssh/id_ed25519.pub"
  # only allow id_ed25519.pub
  update_ssh_server_key "${SSH_SERVER}" "$HOME/.ssh/id_ed25519.pub"
  RETVAL=$(echo "${RETVAL}" | sed 's:,[^,]*$::')
  if [ "${RETVAL}" = "${SSH_SERVER}" ]; then
    break
  fi
done

exit 0

