#!/bin/sh

# This module makes a system backup to a mounted usb drive for the following
# (selectable) items:
#   * user .ssh directory
#   * mozilla firefox profile
#   * evolution profile
#   * dovecot mail archive
#   * exisiting vpn connections
#   * passwords file
#   * software license(s)
#   * ~/backup directory
#   * ~/Maintenance directory
#   * ~/.bash_aliases
#
# Using global variable:
#   "${PSAFEKEY_DIR}": ".local/share/keyrings"
#
# Please select one or more sources to backup: (s/f/e/d/v/p/l/b/m/a) pbm
#
# >>    The following steps require root. Please enter password (hint: ubuntu):
# ...
# Copying from ~/backup ... 
# rsync: [Receiver] getcwd(): No such file or directory (2)
# rsync error: errors selecting input/output files, dirs (code 3) at util1.c(1122) [Receiver=3.2.7]
# Done
# Copying from ~/Maintenance ... 
# rsync: [Receiver] getcwd(): No such file or directory (2)
# rsync error: errors selecting input/output files, dirs (code 3) at util1.c(1122) [Receiver=3.2.7]
# Done
#
# Author: Marc Nijdam, Dec. 2025
# License: MIT
#

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done


##
# internal function to copy psafe3 from local file to USB stick
# $1: "$HOME/${PSAFEKEY_DIR}"
# $2: "psafe3"
# $3: "${PSW_ARCHIVE}"
psafe3_local_to_usb () {
  if [ "$(find "$1" -name "*.$2" | wc -l)" = 1 ]; then
    printf "\nCopying local file to USB stick... "
    PWSAFE_FILE="$(find "$1" -name "*.$2")"
    cd "${PWSAFE_FILE%/*}"
    tar cfj "$(basename "${PWSAFE_FILE}").tar.bz2" "$(basename "${PWSAFE_FILE}")"
    mv "$(basename "${PWSAFE_FILE}").tar.bz2" "${MNTF%/}/$3"
    echo "Done."
    return 0
  fi
  printf "Skipping.\nUnable to determine which $2 file to backup.\n"
  return 1
}


##
# If possible, backup psafe3 file from ssh accessible server to USB stick.
# If not accessible, create a backup of the local psafe file to USB stick.
#
# First try to find the filename (not the file) on the USB-Stick in the
# ${SECRETS_FILE}
# If this file is present and there is an entry for this filename, then use
# that filename.
# If the file is not present, but there is a single psafe3 present at
# ~/.local/share/keyrings/ then use that file. If there are more files, ignore
# backing up.
# 
# $1: Directory where psafe3 password file is stored.
# $2: psafe3 extension ("psafe3")
psafe3_backup () {
    if [ -f "${MNTF%/}/${SECRETS_FILE}" ]; then
      lookup_field "${PWSAFE_DMN_ID}" "${MNTF%/}/${SECRETS_FILE}" "3"
      if [ "$?" = 0 ]; then
       # handle case where no domain is defined so only local storage is used.
        psafe3_local_to_usb "$1" "$2" "${PSW_ARCHIVE}"
        if [ "$?" != 0 ]; then
          return 1
        fi
        return 0
      else
        PWSAFE_FILE="${RETVAL}"
        lookup_field "${PWSAFE_DMN_ID}" "${MNTF%/}/${SECRETS_FILE}" "2"
        if [ "$?" = 0 ]; then
          printf "\n... unable to find domain where ${PWSAFE_FILE} is stored."
          # handle case where no domain is defined so only local storage is used.
          psafe3_local_to_usb "$1" "$2" "${PSW_ARCHIVE}"
          if [ "$?" != 0 ]; then
            return 1
          fi
          return 0
        fi
        # separate domain from entry in file ${SECRETS_FILE} on USB disk.
        PWSAFE_DMN="$(echo "${RETVAL}" | sed 's|:.*||')"
        printf "Found ${PWSAFE_FILE}.\nBacking up from ${PWSAFE_DMN} to USB stick... "
        # Create an archive from downloaded psafe3 file.
        TMP_DIR=$(mktemp -d)
        trap rm_tmp INT
        cd "${TMP_DIR}"
        scp "${RETVAL%/}/$(basename "${PWSAFE_FILE}")" "${TMP_DIR}/$(basename "${PWSAFE_FILE}")"
        tar cjf "$(basename "${PWSAFE_FILE}").tar.bz2" "$(basename "${PWSAFE_FILE}")"
        mv "$(basename "${PWSAFE_FILE}").tar.bz2" "${MNTF%/}/${PSW_ARCHIVE}"
        rm_tmp
        trap - INT
      fi
    else
      # handle case where no domain is defined so only local storage is used.
      psafe3_local_to_usb "$1" "$2" "${PSW_ARCHIVE}"
      if [ "$?" != 0 ]; then
        return 1
      fi
    fi
}

# create tar.bz2 archive of specified file
# $1: source file to be archived (e.g. "$HOME/.bash_aliases")
# $2: target file name (e.g. "bash_aliases.tar.bz2")
# $3: text to be shown to user (e.g. "Backing up bash_aliases")
backup_file () {
  if [ -f "$1" ]; then
    printf "  - $3... "
    tar cjf "${MNTF%/}/$2" -C "$(dirname "$1")/" "$(basename "$1")"
    printf "Done.\n"
  fi
}


licenses_backup () {
  # rar
  backup_file "/etc/rarreg.key" "rarreg.license.tar.bz2" "Backing up rar license"
  # vuescan
  backup_file "$HOME/.vuescanrc" "vuescan.license.tar.bz2" "Backing up vuescan license"
}


## ~/backup, ~/.ssh, ~/.mozilla, /home/vmail ~/Maintenance and evolution"
# SSH_ARCHIVE="sshkeys.tar.bz2"
# MOZ_ARCHIVE="mozilla.profile.tar.bz2"
# VML_ARCHIVE="vmail.tar.bz2"
# EVO_ARCHIVE="evolution-backup-"
# VPN_ARCHIVE="vpn_connections-"
# PSW_ARCHIVE="passwords.tar.bz2"
# RAR_LICENSE="rarreg.key.tar.bz2"
#
# Use dovecot dsync tool to backup email:
#   dsync -f -u <user> backup maildir:<backup_location>
# Ref. https://serverfault.com/questions/758450/make-consistent-copy-of-maildir
#      https://github.com/tachtler/dovecot-backup/blob/master/dovecot_backup.sh
#
echo ">>>> ATTENTION: ABOUT TO CREATE BACKUP. READ CAREFULLY!"
if ps ax -ocomm | grep -q "[f]irefox"; then
  echo "Please close firefox first."
  exit 1
fi
if ps ax -ocomm | grep -e "[e]volution$"; then
  echo "Please close evolution first."
  exit 1
fi
get_mounted_drive || { echo "no USB drive found. Aborting..."; exit 1; }
printf ">>>> ATTENTION: drive ${MNTF} found.\n"
printf "Create a full backup to ${MNTF} or [p]artial backup? (y/n/p)? "
read answer
if [ "$answer" != "${answer#[Yyp]}" ]; then
  if [ "$answer" != "${answer#[p]}" ]; then
    echo "A backup to USB drive can be created from any of the following sources:"
    echo "      (s) ~/.ssh directory"
    echo "      (a) ~/.bash_aliases"
    echo "      (f) ~/.mozilla firefox profile"
    echo "      (e) evolution profile"
    echo "      (d) dovecot mail archive"
    echo "      (v) existing vpn connections" 
    echo "      (p) passwords file"
    echo "      (l) software licenses"
    echo "      (b) ~/backup"
    echo "      (m) ~/Maintenance"
    printf "Please select one or more sources to backup: (s/a/f/e/d/v/p/l/b/m) "
    read bckup
    if [ "$bckup" != "${bckup#[safedvplbm]}" ]; then
      echo
    else
      exit 0
    fi
  else
    # for full backup select all
    bckup="safedvplbm"
  fi
  startsudo
  # 1. ssh
  if echo $bckup | grep -q "s"; then
    printf "Creating archive from files in ~/.ssh directory... "
    # hide strip / warning from tar: https://unix.stackexchange.com/questions/59243/tar-removing-leading-from-member-names
    # temporary tar file should not exist, but if, remove
    rm -f "${MNTF%/}/${SSH_ARCHIVE%.bz2}"
    # select only files, strip ./ from path and update archive
    cd "$HOME/.ssh"
    find . -type f -exec tar -rpf "${MNTF%/}/${SSH_ARCHIVE%.bz2}" --transform='s:^./::' {} \;
    bzip2 "${MNTF%/}/${SSH_ARCHIVE%.bz2}"
    printf "done.\n"
  fi
  # 2. bash_aliases
  if echo $bckup | grep -q "a"; then
    backup_file "$HOME/.bash_aliases" "bash_aliases.tar.bz2" "Backing up bash_aliases"
  fi
  # 3. firefox
  if echo $bckup | grep -q "f"; then
    printf "Creating archive for ~/.mozilla directory... \n"
    SSIZE=$(du -sb  "$HOME/.mozilla" | awk '{print $1}')
    CHECKPOINT=$(echo "${SSIZE}/512/20/50*50/49" | bc)
    echo "Estimated: [==================================================]"
    echo -n "Progress:  ["
    tar cjSf "${MNTF%/}/${MOZ_ARCHIVE}" --checkpoint=${CHECKPOINT} --checkpoint-action=dot -C / "${HOME#/}/.mozilla"
    echo "]"      
  fi
  # 4. evolution
  if echo $bckup | grep -q "e"; then
    # https://unix.stackexchange.com/questions/723451/how-to-make-a-valid-backup-for-evolution-and-restore-it
    if command -v /usr/libexec/evolution/evolution-backup 2>&1 >/dev/null; then
      printf "Removing old backup and creating new backup for evolution... "
      find "${MNTF%/}" -maxdepth 1 -type f -name "${EVO_ARCHIVE%-}*.tar.gz" -delete
      /usr/libexec/evolution/evolution-backup --backup ${MNTF%/}/${EVO_ARCHIVE}$(date '+%Y%m%d').tar.gz >/dev/null 2>&1
      printf "done.\n"
    else
      echo "Skipping creating backup for evolution. evolution-backup not found."
    fi      
  fi
  # 5. dovecot mail archive without leading / , i.e.: home/vmail/${HOME#/home/}@localstor/...
  if echo $bckup | grep -q "d"; then
    WORK_DIR=$(mktemp -d -p "/tmp")
    sudo chown ${DUSRGRP}:${DUSRGRP} "${WORK_DIR}"
    # 1. first create backup using doveadm
    printf "Creating local backup for dovecot user ${HOME#/home/}@${DDOMAIN}. This may take a while... \n"
    sudo doveadm -v backup -u "${HOME#/home/}@${DDOMAIN}" "maildir:${WORK_DIR}/${HOME#/home/}@${DDOMAIN}"
    # 2. create archive
    printf "Creating archive from mail backup directory... \n"
    SSIZE=$(sudo du -sb  "${WORK_DIR}/" | awk '{print $1}')
    CHECKPOINT=$(echo "${SSIZE}/512/20/50" | bc)
    echo "Estimated: [==================================================]"
    echo -n "Progress:  ["
    sudo tar cjSf "${MNTF%/}/${VML_ARCHIVE}" --checkpoint=${CHECKPOINT} --checkpoint-action=dot -C "${WORK_DIR}" "${HOME#/home/}@${DDOMAIN}"
    echo "]"
    sudo chown ${HOME#/home/}:${HOME#/home/} "${MNTF%/}/${VML_ARCHIVE}"
    # remove temporary directory, since we have now all mail in an archive as tar.bz2 backup
    sudo rm -Rf "${WORK_DIR}"
  fi
  # 6. backup defined vpn connections to USB disk
  #    https://gist.github.com/qiwichupa/2c1828232fd23258aeb78ac3808bd729
  if echo $bckup | grep -q "v"; then
    printf "backing up existing vpn connections\n"
     export_all_vpn_connections "${MNTF%/}/${VPN_ARCHIVE}$(date '+%Y%m%d').tar.bz2"
  fi
  # 7. backup passwords file to USB disk
  if echo $bckup | grep -q "p"; then
    printf "backing up existing passwords file... "
    psafe3_backup "$HOME/${PSAFEKEY_DIR}" "psafe3"
    if [ "$?" != 0 ]; then
      printf "Error\n"
    fi
  fi
  # 8. backup licenses to USB disk
  if echo $bckup | grep -q "l"; then
    printf "backing up existing software licenses...\n"
    licenses_backup
  fi
  cd "$HOME"
  # 9. rsync ~/backup
  if echo $bckup | grep -q "b"; then
    printf "Copying from ~/backup ... \n"
    rsync -az --delete --info=progress2 --no-i-r --partial "$HOME/backup/" "${MNTF%/}/backup"
    printf "Done\n"
  fi
  # 10. rsync ~/Maintenance
  if echo $bckup | grep -q "m"; then
    printf "Copying from ~/Maintenance ... \n"
    rsync -az --delete --info=progress2 --no-i-r --partial "$HOME/Maintenance/" "${MNTF%/}/Maintenance"
    printf "Done\n"      
  fi
fi
stopsudo

exit 0
