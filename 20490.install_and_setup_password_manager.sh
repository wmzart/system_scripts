#!/bin/sh

# license: gpl
# This script installs pwsafe - Secure Password Manager 
# Additionally it adds a wrapper script which let the password file always be
# synchronized to a remote ssh server.
#
# This script expects the following:
#   - a file "domains.csv" on a USB stick with at least a line with a definition
#     for an ssh accessible domain: an identifier, the domain in the format
#     USER@DOMAIN and file containing the encrypted password (called safe) in
#     the following format:
#
#     "DOMAIN_PWSAFE";"USER@DOMAIN:PATH";"FILE.psafe3"
#
# Where USER@DOMAIN needs to be replaced with an ssh accessible domain in the
# format USER@DOMAIN and FILE (with the extension psafe3) to be replaced with
# the filename of the pwsafe file. E.g. squirrel.psafe3
#
# Then, on the ssh server, there needs to be a path from the main directory with
# the psafe3 file in it, like:
#
#     "DOMAIN:PATH1/PATH2/FILE.psafe3"
#
# The script expects the ssh server to have passwordless access and the psafe3
# file to be initially on the server at PATH1/PATH2/FILE.psafe3
# If the file is not present at the server, the script execution aborts.
#
# As with all scripts in this series, it should be possible to execute multiple
# times, without modifying an existing setup/installation.
#
# Needs global variable PWSAFE_DMN_ID (equal to "DOMAIN_PWSAFE") which is used
# to lookup an entry in the file on USB-Disk domains.csv
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


PWD_NAME="pwsafe.desktop"
PWS_DIR="$HOME/Maintenance/apps/pwsafe/"
PWS_SCRPT="pwsafesync"
PWO_DIR="/usr/share/applications/"
KEY_DIR="$HOME/.local/share/keyrings/"

## sanitize paths
PWS_DIR="${PWS_DIR%/}"
PWO_DIR="${PWO_DIR%/}"
KEY_DIR="${KEY_DIR%/}"

get_mounted_drive "${SECRETS_FILE}" || { echo "Please put a file with a list of key/value definitions on the main directory of a USB-drive."; exit 1; }
printf ">>>> CHECKING REQUIREMENTS:\n  - File with list of key/value definitions ("${SECRETS_FILE}") found on USB-drive.\n"

# Using ID "DOMAIN_PWSAFE" to search for in ${SECRETS_FILE} file on USB disk.
# PWSAFE_DMN_ID defined in global_variables.sh
lookup_field "${PWSAFE_DMN_ID}" "${MNTF%/}/${SECRETS_FILE}" 2
if [ "$?" = 0 ]; then
  echo "There is no key defined in the file ${SECRETS_FILE} on USB-stick with identifier \"${PWSAFE_DMN_ID}\""
  exit 1
fi
# separate domain and path from entry in file ${SECRETS_FILE} on USB disk.
DOMAIN="$(echo "${RETVAL}" | sed 's|:.*||')"
PWSR_PATH="$(echo "${RETVAL%/}" | sed 's|.*:||')"

## check if passwordless authentication is possible
ssh -o PasswordAuthentication=no -o BatchMode=yes $DOMAIN exit &>/dev/null
if [ "$?" != 0 ]; then
  echo "the domain ${DOMAIN} does not allow passwordless authentication (required). Aborting..."
  exit 1
else
  echo "  - FQDN ${DOMAIN} will be used in setting up password manager."
fi

## retrieve filename for pwsafe from domain
lookup_field "${PWSAFE_DMN_ID}" "${MNTF%/}/${SECRETS_FILE}" 3
if [ "$?" = 0 ]; then
  echo "Password filename missing in the file ${SECRETS_FILE} on USB-stick with identifier \"${PWSAFE_DMN_ID}\"."
  echo "Aborting..."
  exit 1
fi

## check if password file is present on the server
PWS_DATA="${RETVAL}"
ssh -o PasswordAuthentication=no -o BatchMode=yes $DOMAIN "test -f ${PWSR_PATH}/${PWS_DATA}  && exit 0 || exit 1"
if [ "$?" != 0 ]; then
  echo "Password file missing at ${DOMAIN}:${PWSR_PATH}/${PWS_DATA}. Aborting..."
  exit 1
else
  echo "  - Using ${PWS_DATA} stored at ${DOMAIN}:${PWSR_PATH}/."
fi

## copying over the password file from the server
if [ -f "${KEY_DIR}/${PWS_DATA}" ]; then
  # check md5 sum local and remote and if different then:
  MD5REM=$(ssh -o PasswordAuthentication=no -o BatchMode=yes $DOMAIN "md5sum ${PWSR_PATH}/${PWS_DATA}" | sed -nr 's#^([[:xdigit:]]{32}).*#\1#p')
  MD5LOC=$(md5sum "${KEY_DIR}/${PWS_DATA}" | sed -nr 's#^([[:xdigit:]]{32}).*#\1#p')
  if [ "${MD5REM}" != "${MD5LOC}" ]; then
    printf "ABORTING TO PREVENT OVERWRITING ${KEY_DIR}/${PWS_DATA}\n"
    exit 1
  else
    echo "  - Local database is already present and the same as the remote one."
  fi
else
  echo ">>    Creating directory for password file."
  mkdir -p "${KEY_DIR}"
  # copy psafe3 file from web MAIN_DOMAIN at InSync/pwsafe/ into previous directory
  echo ">>    Copy password file from server to previously created directory..."
  rsync -avztu "${DOMAIN}:${PWSR_PATH}/${PWS_DATA}" "${KEY_DIR}/${PWS_DATA}" || { echo "Aborting"; exit 1; }
  printf "Done.\n"
fi


## test if pwsafe is already installed
if command -v "pwsafe" >/dev/null 2>&1; then
  echo "  - Program passwordsafe already installed."
else 
  echo ">>>> ATTENTION: ABOUT TO INSTALL PWSAFE. READ CAREFULLY!"
  startsudo
  echo ">>    Installing passwordsafe..."
  sudo apt-get -y install passwordsafe
fi


## test if pwsafesync script is already installed
histchars=
q="#!/bin/bash\n"
q="${q}rmd=\"${PWSR_PATH}/\"\n"
q="${q}pws=\"/usr/bin/pwsafe\"\n"
q="${q}sfl=\"${PWS_DATA}\"\n"
q="${q}mdf=\"/usr/bin/md5sum\"\n\n"
q="${q}wget -q --spider \"http://${DOMAIN#*@}\"\n"
q="${q}if [ \"\$?\" != 0 ]; then\n"
q="${q}# No connection available. Synchronisation skipped.\n"
q="${q}  \$pws \"${KEY_DIR}/\${sfl}\"\n"
q="${q}else\n"
q="${q}  mdx=\$(\$mdf ${KEY_DIR}/\${sfl})\n"
q="${q}  export DISPLAY=:0\n"
q="${q}  ssh \"${DOMAIN}\" \"cp -f \${rmd}\${sfl} \${rmd}\${sfl}.bak\"\n"
q="${q}  /usr/bin/rsync -avztu \"${KEY_DIR}/\${sfl}\" \"${DOMAIN}:\${rmd}\"\n"
q="${q}  /usr/bin/rsync -avztu \"${DOMAIN}\":\${rmd}\${sfl} \"${KEY_DIR}/\${sfl}\"\n"
q="${q}  mdz=\$(\$mdf ${KEY_DIR}/\${sfl})\n"
q="${q}  if [ \"\$mdz\" != \"\$mdx\" ]; then\n"
q="${q}    notify-send \"pwsafesync\" \"pwsafe updated from server\"\n"
q="${q}  fi\n\n"
q="${q}  \$pws \"${KEY_DIR}/\${sfl}\"\n"
q="${q}  if [ \"\$mdz\" != \"\$(\$mdf ${KEY_DIR}/\${sfl})\" ]; then\n"
q="${q}    /usr/bin/rsync -avzt \"${KEY_DIR}/\${sfl}\" \"${DOMAIN}:\${rmd}\"\n"
q="${q}    notify-send \"pwsafesync\" \"pwsafe changes updated to server\"\n"
q="${q}  fi\n"
q="${q}  ssh \"${DOMAIN}\" \"rm -f \${rmd}\${sfl}.bak\"\n"
q="${q}fi"
unset histchars
printf "${q}\n" > "${PWS_DIR}/${PWS_SCRPT}.tmp"
if [ -f "${PWS_DIR}/${PWS_SCRPT}" ] && cmp -s "${PWS_DIR}/${PWS_SCRPT}" "${PWS_DIR}/${PWS_SCRPT}.tmp"; then
  echo "  - Script pwsafesync is present and already the latest."
else
  echo ">>>> (OVER)WRITING PWSAFESYNC SCRIPT."
  mkdir -p ${PWS_DIR}
  printf "${q}\n" > "${PWS_DIR}/${PWS_SCRPT}"
  chmod +x "${PWS_DIR}/${PWS_SCRPT}"
fi
rm -f "${PWS_DIR}/${PWS_SCRPT}.tmp"

## overwrite pwsafe.desktop file with replacement pwsafe.desktop file
# This will make it possible that the script handles synchronization and
# starts PasswordSafe. (Backup old pwsafe.desktop file)

echo "  - Creating backup of pwsafe.desktop file to \$HOME/${PWS_DIR#*/*/*/}/${PWD_NAME}_ORIG"
cp "${PWO_DIR}/${PWD_NAME}" "${PWS_DIR}/${PWD_NAME}_ORIG"
histchars=
q="[Desktop Entry]\n"
q="${q}Name=PasswordSafe\n"
q="${q}Exec=${PWS_DIR}/${PWS_SCRPT}\n"
q="${q}Comment=Manage passwords\n"
q="${q}Icon=pwsafe\n"
q="${q}Type=Application\n"
q="${q}StartupNotify=true\n"
q="${q}StartupWMClass=pwsafe\n"
q="${q}Categories=Utility;Security;"
unset histchars
printf "${q}\n" > "${PWS_DIR}/${PWD_NAME}.tmp"
if [ -f "${PWS_DIR}/${PWS_SCRPT}" ] && cmp -s "${PWO_DIR}/${PWD_NAME}" "${PWS_DIR}/${PWD_NAME}.tmp"; then
  echo "  - Desktop file ${PWD_NAME} is present and already the latest."
else  
  echo ">>>> ATTENTION: INSTALLING DESKTOP FILE."
  startsudo
  printf "${q}\n" | sudo tee "${PWO_DIR}/${PWD_NAME}" >/dev/null
fi
rm -f "${PWS_DIR}/${PWD_NAME}.tmp"

stopsudo
exit 0
