#!/bin/sh

# This script performs a setup of dovecot as a local mail server. This will
# reduce the dependency of used formats on a systems' mail cient, as well make
# sure the mail client does not have to deal with very large mail boxes.
#
# Additionally, a read-only mailbox will be setup, with the benefit to have
# e-mail folders archived without worrying about having deleted one or more
# mails.
# With the additional mail account, evolution is able to show the same folder
# either as ${USER}@${DDOMAIN} or read-only ${DRO_USER}@${DDOMAIN}. It is highly
# recommended for daily use to enable only the read only mail account, to
# prevent unexpected deletion or addition of mails. The ${USER}@${DDOMAIN}
# should be only then enabled when the mail account needs to be updated.
#
# This script requires/assumes the following variables which are defined in
# the files 00000.global_variables.sh and 00005.dovecot_settings.sh
#
#  ${HOME#/home/} Default user, taken from $HOME
#  VML_ARCHIVE    Filename of the (potentially large) mail archive: vmail.tar.bz2
#  DDOMAIN        local domain/mailbox name containing all mail. E.g. localdomain
#  DUSRID         Dovecot user id: 10000
#  DUSRGRP        Dovecot group: vmail, also used for creating /home/vmail
#  DEF_PASWD      Initial password for accessing the mails via dovecot: ubuntu
#  DRO_USER       Name of the read only user. (Currently set to: readonly)
#
# As with all scripts in this series, it should be possible to execute multiple
# times, without modifying an existing setup/installation.
#
# troubleshoot with: journalctl -xeu dovecot.service
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


create_distribute_acl_script() {
  # create directory if not already there
  [ -d "$(dirname "$1")" ] || mkdir -p "$(dirname "$1")"

  # return if file is already there
  [ -f "$1" ] && return

  ## Write dovecot helper script for distributing dovecot-acl file to user
  ## for IMAP ACL
  histchars=
  q='#!/bin/bash\n'
  q=$q'# 1. create a dovecot-acl file in /home/vmail/USER@localdomain/Maildir/ with:\n'
  q=$q'#    owner lrwstipekxa"\n'
  q=$q'#    user=readonly@localdomain lr\n'
  q=$q'# 2. Invoke this script with sudo and as argument the users e-mail address (user@localdomain)\n'
  q=$q'#    sudo ./distribute_acl.sh "user@localdomain" "/home/vmail"\n\n'
  q=$q'# call with arguments:\n'
  q=$q'# $1 = user@localdomain\n'
  q=$q'# $2 = mailroot (/home/vmail)\n\n'
  q=$q'IFS_BAK=$IFS\n'
  q=$q'IFS="\n'
  q=$q'"\n'
  q=$q'\n'
  q=$q'MAILBOX="${2%/}/$1/Maildir"\n'
  q=$q'ACLFILE="$MAILBOX/dovecot-acl"\n'
  q=$q'if [ -d "$MAILBOX" ]; then\n'
  q=$q'  echo "Working on mailbox $1..."\n\n'
  q=$q'  # Make sure we have an ACL file\n'
  q=$q'  if [ -f "$ACLFILE" ]; then\n'
  q=$q'    echo "Found ACL file in mailbox $1..."\n'
  q=$q'  else\n'
  q=$q'    echo "ACL not found. Aborting"\n'
  q=$q'    exit 1\n'
  q=$q'  fi\n'
  q=$q'  echo "starting point at ${MAILBOX}... "\n'
  q=$q'  # Copy the ACL file to sub directories\n'
  q=$q'  for dir in `find $MAILBOX -type d -name "*"`; do\n'
  q=$q'    # skip copying dovecot-acl to directories cur, new and tmp\n'
  q=$q'    if [ $(basename ${dir}) = "cur" ]; then\n'
  q=$q'      continue\n'
  q=$q'    fi\n'
  q=$q'    if [ $(basename ${dir}) = "new" ]; then\n'
  q=$q'      continue\n'
  q=$q'    fi\n'
  q=$q'    if [ $(basename ${dir}) = "tmp" ]; then\n'
  q=$q'      continue\n'
  q=$q'    fi\n'
  q=$q'    # skip copying dovecot-acl to Maildir if it exists already.\n'
  q=$q'    if [ "$MAILBOX/dovecot-acl" = "$dir/dovecot-acl" ]; then\n'
  q=$q'      continue\n'
  q=$q'    fi\n'
  q=$q'    echo "adding dovecot-acl to $dir"\n'
  q=$q'    cp -av $MAILBOX/dovecot-acl "$dir/"\n'
  q=$q'  done\n'
  q=$q'  # Remove the dovecot-acl-list to make the mailboxes appear\n'
  q=$q'  if [ -f "$ACLFILE-list" ]; then\n'
  q=$q'    rm "$ACLFILE-list"\n'
  q=$q'  fi\n'
  q=$q'else\n'
  q=$q'  echo "Mailbox $1 does not exist"\n'
  q=$q'  exit 1\n'
  q=$q'fi\n\n'
  q=$q'IFS=$IFS_BAK\n'
  q=$q'IFS_BAK='
  # replace \n with newline and write to file
  printf "%s\n" "$q" | awk '{gsub(/\\n/,"\n")}1' > "$1"
  unset histchars

  # make script executable
  chmod +x "$1"
}


create_set_mail_folder_perms_script() {
  # create directory if not already there
  [ -d "$(dirname "$1")" ] || mkdir -p "$(dirname "$1")"

  # return if file is already there
  [ -f "$1" ] && return

  q='#!/bin/bash\n'
  q=$q'# This script lists all folders from user $1 and\n'
  q=$q'# sets then $4 permissions for the share to user $3\n'
  q=$q'# using the password $2 for user $1\n'
  q=$q'echo "==========================================================="\n'
  q=$q'echo "permission settings for user $3: $4"\n'
  q=$q'echo\n'
  q=$q'# version without sudo rights:\n'
  q=$q'RET="$( (echo "a1 LOGIN $1 $2"; sleep 0.5; echo "a2 LIST \"\" \"*\""; sleep 0.5; echo "a4 LOGOUT") | telnet 127.0.0.1 143 2>/dev/null)"\n'
  q=$q'while IFS= read -r line; do\n'
  q=$q'  MFLDR="$(echo "${line}" | grep "^\* LIST" | sed "s/\"//g" | grep -o "/.*" | cut -d"/" -f2- | sed "s/^[[:space:]]*//g")"\n'
  q=$q'  if [ ! -z "$MFLDR" ]; then\n'
  q=$q'    printf "Setting permissions for: $MFLDR... "\n'
  q=$q'    (echo "a1 LOGIN $1 $2"; sleep 0.1; echo "a3 SETACL \"${MFLDR}\" $3 $4"; sleep 0.1; echo "a4 LOGOUT"; sleep 0.1 ) | telnet 127.0.0.1 143 | grep "OK Setacl complete" | cut -d" " -f2- 2>/dev/null\n'
  q=$q'  fi\n'
  q=$q'done <<< "${RET}" 2>/dev/null'
  # replace \n with newline and write to file
  printf "%s\n" "$q" | awk '{gsub(/\\n/,"\n")}1' > "$1"
  unset histchars

  # make script executable
  chmod +x "$1"
}


## Create virtual dovecot user in /etc/dovecot/users
# $1 user@domain
# $2 password
create_dovecot_user () {
  if [ -f /etc/dovecot/users ]; then
    if grep -q "$1" /etc/dovecot/users; then
      return
    fi
  fi
  printf ">>    Creating dovecot mail user with password $2...\n"
  # create the user name in the user file
  # When using plaintext authentication, see note 5).
  lsha512=$(sudo doveadm pw -s SHA512-CRYPT -p $2)
  echo "$1:${lsha512#*\}}:$(id -u ${DUSRGRP}):$(getent group ${DUSRGRP} | cut -d: -f3)::/home/${DUSRGRP}/$1/::" | sudo tee -a /etc/dovecot/users
}


## create dovecot acl file
# $1 main user
# $2 readonly user
# $3 permissions for readonly user
create_dovecot_acl_file () {
  histchars=
  q="owner lrwstipekxa\n"
  q="${q}user=$2 $3"
  printf "${q}\n" | sudo -u ${DUSRGRP} -g ${DUSRGRP} tee "/home/${DUSRGRP}/$1/Maildir/dovecot-acl"
  unset histchars
}


##
# Ref. https://doc.dovecot.org/2.4.0/core/config/shared_mailboxes.html
setup_dovecot_and_mail () {
  echo ">>>> ATTENTION: ABOUT TO INSTALL DOVECOT / MAIL ARCHIVE. READ CAREFULLY!"
  startsudo
  if ! command -v dovecot 2>&1 >/dev/null; then
    printf ">>    Installing dovecot...\n"
    sudo apt-get update
    sudo apt-get -y install dovecot-imapd
    systemctl is-active --quiet dovecot || { echo >&2 "Problem with dovecot installation. Aborting."; return 1; }
    printf ">>    Temporarily stopping dovecot service...\n"
    sudo service dovecot stop
    # add vmail system user
    printf ">>    Adding ${DUSRGRP} user with user ID $DUSRID}...\n"
    if cat /etc/passwd | awk -F: '{print $3}' | grep -q "^${DUSRID}$"; then
      echo "User ID ${DUSRID} is already present, please try with another user ID"
    else
      sudo adduser --system --home /home/${DUSRGRP} --uid ${DUSRID} --group ${DUSRGRP}
      sudo chmod 770 /home/${DUSRGRP}
    fi
    # dovecot configuration
    printf ">>    Writing configuration...\n"
    histchars=
    q="import_environment = \$import_environment PR_SET_DUMPABLE=1\n"
    q="${q}protocols = imap\n"
    q="${q}disable_plaintext_auth = no\n\n"
    q="${q}mail_home = /home/${DUSRGRP}/%u\n"
    q="${q}mail_location = maildir:~/Maildir:LAYOUT=fs\n\n"
    q="${q}namespace inbox {\n"
    q="${q}  separator = /\n"
    q="${q}  #location defaults to mail_location.\n"
    q="${q}  inbox = yes\n"
    q="${q}  list = yes\n"
    q="${q}}\n\n"
    q="${q}namespace shared {\n"
    q="${q}  type = shared\n"
    q="${q}  separator = /\n"
    q="${q}  prefix = shared/%%u/ \n"
    q="${q}  location = maildir:%%h/Maildir:LAYOUT=fs\n"
    q="${q}  list = children\n"
    q="${q}}\n\n"
    q="${q}mail_plugins = acl\n"
    q="${q}protocol imap {\n"
    q="${q}  mail_plugins = \$mail_plugins imap_acl\n"
    q="${q}}\n\n"
    q="${q}service imap-login {\n"
    q="${q}  inet_listener imap {\n"
    q="${q}  }\n"
    q="${q}  inet_listener imaps {\n"
    q="${q}    port = 0\n"
    q="${q}  }\n"
    q="${q}}\n\n"
    q="${q}plugin {\n"
    q="${q}  acl = vfile\n"
    q="${q}  acl_shared_dict = file:/var/lib/dovecot/db/shared-mailboxes.db\n"
    q="${q}}\n\n"
    q="${q}service auth {\n"
    q="${q}  unix_listener auth-userdb {\n"
    q="${q}    user = ${DUSRGRP}\n"
    q="${q}    group = ${DUSRGRP}\n"
    q="${q}  }\n"
    q="${q}}\n\n"
    q="${q}passdb {\n"
    q="${q}  driver = passwd-file\n"
    q="${q}  args = scheme=SHA512-CRYPT username_format=%u /etc/dovecot/users\n"
    q="${q}}\n\n"
    q="${q}userdb {\n"
    q="${q}  driver = passwd-file\n"
    q="${q}  args = username_format=%u /etc/dovecot/users\n"
    q="${q}}"
    # replace \n with newline and escape dollar if required
    printf "%s\n" "$q" | sed 's|\\n|\n|g' | sudo tee /etc/dovecot/local.conf
    unset histchars
    # The default authentication method will not be used. However, there is no option to disable
    # the default setting from within the local.conf file. So to disable this, overwrite this
    # setting in the default configuration file in the conf.d directory.
    # Specifically comment out the binding in: 10-auth.conf
    sudo sed -i 's/^!include auth-system.conf.ext/##!include auth-system.conf.ext/' /etc/dovecot/conf.d/10-auth.conf

    # The default folders like Trash, Junk, Sent are not relevent. Hide them
    # per default
    sudo sed -i -e "s/^\(.*\)/##\1/" /etc/dovecot/conf.d/15-mailboxes.conf

    # create main dovecot user
    if [ -f /etc/dovecot/users ]; then
      if ! grep -q "${HOME#/home/}@${DDOMAIN}" /etc/dovecot/users; then
        create_dovecot_user "${HOME#/home/}@${DDOMAIN}" "${DEF_PASWD}"
      fi
      # create readonly dovecot user
      if ! grep -q "${DRO_USER}@${DDOMAIN}" /etc/dovecot/users; then
        create_dovecot_user "${DRO_USER}@${DDOMAIN}" "${DEF_PASWD}"
      fi
    else
      create_dovecot_user "${HOME#/home/}@${DDOMAIN}" "${DEF_PASWD}"
      create_dovecot_user "${DRO_USER}@${DDOMAIN}" "${DEF_PASWD}"
    fi
  else
    printf ">>    dovecot already installed, stopping dovecot service...\n"
    sudo service dovecot stop
    sleep 1
  fi
  # copying backup from external drive
  printf ">>    Copy mail archive...\n"
  cd
  if [ -n "${BSFN}" -a -f "${MNTF%/}/${BSFN}" ]; then
    printf ">>>> ATTENTION: archive ${BSFN} found.\n"
    printf "Do you wish to import into /home/${DUSRGRP}? (y/n)? "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ]; then
      WORK_DIR=$(mktemp -d -p "/tmp")
      sudo chown ${DUSRGRP}:${DUSRGRP} "${WORK_DIR}"
      SSIZE=$(stat -c %s "${MNTF%/}/${BSFN}")
      CHECKPOINT=$(echo "${SSIZE}/512/20/50*50/31" | bc)
      echo "Estimated: [==================================================]"
      echo -n "Progress:  ["
      # --strip-components=2
      sudo tar xjf "${MNTF%/}/${BSFN}" --checkpoint=${CHECKPOINT} --checkpoint-action=dot -C "${WORK_DIR}"
      echo "]"
      # empty mail folders for main user 
      echo "Trying to delete files in /home/${DUSRGRP}/${HOME#/home/}@${DDOMAIN}/"
      sudo rm -Rf "/home/${DUSRGRP}/${HOME#/home/}@${DDOMAIN}/Maildir/{*,.*}"
      # empty mail folders for readonly user 
      echo "Trying to delete files in /home/${DUSRGRP}/${DRO_USER}@${DDOMAIN}/"
      sudo rm -Rf "/home/${DUSRGRP}/${DRO_USER}@${DDOMAIN}/Maildir/{*,.*}"
      printf ">>    restarting dovecot service...\n"
      sudo service dovecot start
      sleep 1

      # import mail for main user
      echo "Importing mail archive for user ${HOME#/home/}@${DDOMAIN}"
      sudo doveadm -v import -u "${HOME#/home/}@${DDOMAIN}" maildir:/${WORK_DIR}/${HOME#/home/}@${DDOMAIN} "" ALL
      printf "Done.\n"
      
      # import succesful, delete temporary WORK_DIR
      sudo rm -Rf "${WORK_DIR}"

      ## create dovecot-acl file for main user
      create_dovecot_acl_file "${HOME#/home/}@${DDOMAIN}" "${DRO_USER}@${DDOMAIN}" "lr"

      ## write the dovecot-acl file to all Maildir (sub)directories using a
      # helper script distribute_acl.sh in $HOME/Maintenance/apps/dovecot
      create_distribute_acl_script "$HOME/Maintenance/apps/dovecot/distribute_acl.sh"

      # execute distribute_acl.sh
      sudo "$HOME/Maintenance/apps/dovecot/distribute_acl.sh" "${HOME#/home/}@${DDOMAIN}" "/home/${DUSRGRP}"

      ## create dovecot-acl file for read only user
      create_dovecot_acl_file "${DRO_USER}@${DDOMAIN}" "${DRO_USER}@${DDOMAIN}" "lr"

      # create helper script distribute_acl.sh in $HOME/Maintenance/apps/dovecot
      create_set_mail_folder_perms_script "$HOME/Maintenance/apps/dovecot/set_mail_folder_permissions.sh"

      # populate shared-mailboxes.db in /var/lib/dovecot/db
      # this file should be writable and contain something but somehow it is
      # empty per default, causing shared mailboxes not work.
      # check with:
      #   sudo doveadm acl debug -u DRO_USER@DDOMAIN shared/USER@DDOMAIN
      #   doveadm(DRO_USER@DDOMAIN): Info: Mailbox 'INBOX' is in namespace 'shared/USER@DDOMAIN/'
      #   doveadm(DRO_USER@DDOMAIN): Info: Mailbox path: /home/vmail/USER@DDOMAIN//Maildir
      #   doveadm(DRO_USER@DDOMAIN): Info: All message flags are shared across users in mailbox
      #   doveadm(DRO_USER@DDOMAIN): Info: User DRO_USER@DDOMAIN has rights: lookup read
      #   doveadm(DRO_USER@DDOMAIN): Info: Mailbox found from dovecot-acl-list
      #   doveadm(DRO_USER@DDOMAIN): Info: User USER@DDOMAIN found from ACL shared dict
      #   doveadm(DRO_USER@DDOMAIN): Info: Mailbox shared/USER@DDOMAIN is visible in LIST
      # Interestingly, when emptying the file /var/lib/dovecot/shared-mailboxes.db and then
      # issuing the command from above, the output writes that it rebuilds ACL shared dict.
      # It cannot find user USER@DDOMAIN. But afterwards it writes that user
      # USER@DDOMAIN found from ACL shared dict.
      
      # https://dovecot.org/mailman3/archives/list/dovecot@dovecot.org/thread/5LSX6LOX5LF5Z2VOT3O6AD7QKCV5U2LK/
      sudo mkdir -p /var/lib/dovecot/db
      sudo chown "${DUSRGRP}:${DUSRGRP}" /var/lib/dovecot/db
      printf "shared/shared-boxes/user/${DRO_USER}@${DDOMAIN}/${USER}@${DDOMAIN}\n1\n" | sudo tee /var/lib/dovecot/db/shared-mailboxes.db
      sudo chown vmail:vmail /var/lib/dovecot/db/shared-mailboxes.db


      ## set rl permissions for user read only user
      "$HOME/Maintenance/apps/dovecot/set_mail_folder_permissions.sh" "${HOME#/home/}@${DDOMAIN}" "${DEF_PASWD}" "${DRO_USER}@${DDOMAIN}" "lr"
      printf "All done.\n"
      printf "IN ORDER TO SEE ALL FOLDERS, MAKE SURE TO SUBSCRIBE TO THEM!\n"
    fi
  fi
  stopsudo
  return 0
}


## Changes made to files in /etc/dovecot/conf.d/
# 10-auth.conf:
#               !include auth-system.conf.ext -> #!include auth-system.conf.ext
# 10-mail.conf:
#               namespace inbox { -> #namespace inbox {
#               inbox = yes -> #inbox = yes
#               } -> #}
#               mail_privileged_group = mail -> #mail_privileged_group = mail
# 15-mailboxes.conf:
#               namespace inbox { -> #namespace inbox {
#  mailbox Drafts { -> #mailbox Drafts {
#    special_use = \Drafts -> #  special_use = \Drafts
#  } -> #}
# mailbox Junk { -> #mailbox Junk {
#    special_use = \Junk -> #special_use = \Junk
#  } -> #}
#  mailbox Trash { -> #mailbox Trash {
#    special_use = \Trash -> #special_use = \Trash
#  } -> #}
#  mailbox Sent { -> #mailbox Sent {
#    special_use = \Sent -> #special_use = \Sent
#  } -> #}
#  mailbox "Sent Messages" { -> #mailbox "Sent Messages" {
#    special_use = \Sent -> #special_use = \Sent
#  } -> #}
# } -> #}
# auth-system.conf.ext: All commented out, but likely sufficient to change the binding in 10-auth.conf


# authentification in auth-system.conf.ext:
# sudo sed -i -e  's/^\([^#]\)/#>\1/g' /etc/dovecot/conf.d/auth-system.conf.ext

##############################
#
# >>>>> CODE ENTRY POINT <<<<<
#


# Retrieve MNTF for mountpoint and BSFN for basename, based on the vmail.tar.gz
# file which should be present in the main directory of the USB drive.
get_mounted_drive "${VML_ARCHIVE}" || { echo "usb drive not found and/or mail archive on usb drive not present."; exit 1; }

# With the mail archive file found, start setting up dovecot, using following variables:
#   "${HOME#/home/}"
#   "${DDOMAIN}"
#   "${DUSRID}"
#   "${DUSRGRP}"
#   "${DEF_PASWD}"
#   "${DRO_USER}"
#   "${MNTF}"
#   "${BSFN}"
#
startsudo
setup_dovecot_and_mail || exit 1
stopsudo
printf "Done.\n"
exit 0
