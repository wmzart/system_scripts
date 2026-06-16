#!/bin/sh

# This module provides functions to import/export existing openvpn connections
# from/to a system, using nmcli, the command-line tool for controlling
# NetworkManager.
# Written by M.Nijdam, Jan. 2026
# License: MIT

# $1: name of openvpn connection to be exported
# $2: filename for the to be exported openvpn connection
openvpn_export () {
  #  doublecheck
  if !  nmcli connection export "$1" > /dev/null 2>&1; then
      echo "ERROR. Export error."
      exit 1
  fi

  rm -f "${2%/*}certfiles"
  grepstr=""
  CONF=$(nmcli connection export "$1")
  # save all certs to tmp file
  for x in cert key ca tls-crypt tls-auth; do
    if echo "$CONF" | grep -q "^$x "; then
      file=$(realpath $(echo "$CONF" | grep ^$x| cut -d " " -f 2 | sed  "s/'//g") )
      if [ -e $file ]; then
        echo "<$x>" >> "${2%/*}certfiles"
        cat "$file" >> "${2%/*}certfiles"
        echo "</$x>" >> "${2%/*}certfiles"
      fi
    fi
    grepstr="${grepstr}^$x |"
  done

  # remove lines with files from config
  echo "$CONF"| grep -vE  "${grepstr%|}" > "$2"
  # add saved certs
  cat "${2%/*}certfiles" >> "$2"
  rm -f "${2%/*}certfiles"
}

## import openvpn connections, extracted from provided openvpn file/definitions
# $1: name of the ovpn file
# $2: (optional) name of the accompanied txt file containing username and password
#
# For each connections we need to do the following:
#     nmcli connection import file "${CONN}.ovpn" type openvpn
#     # fix missing password settings which nmcli did not import
#     nmcli connection modify "${CONN}" +vpn.data username=MYUSERNAME
#     nmcli connection modify "${CONN}" +vpn.secrets "password=MYSECRET"
#     # fix missing vpn.data which nmcli did not export but are required
#     nmcli connection modify "${CONN}" +vpn.data "auth=SHA256"
#     nmcli connection modify "${CONN}" +vpn.data "ta-dir=1"
# Where "${CONN}" corresponds to the name of the vpn connection as shown in the
# network manager.
# 
# Just for reference:
#   fix possible pfsense ovpn client export incompatibility, based on presence
#   of a definition about the tls-client. A better solution would be to change
#   the certificate though. Anyway, if necessary, something like the following
#   would be possible:
#      if ! grep -q -e "^tls-cert-profile insecure" "$1"; then
#        # add tls-cert-profile insecure
#        printf "fix vpn-directives... "
#        sed -i '/^tls-client.*/a tls-cert-profile insecure' "$1"
#      fi
openvpn_import () {
  printf "importing... "
  # Add reference to username and password for openvpn if pass.txt exists
  if grep -q "^auth-user-pass$" "$1"; then
    sed -i "s/^auth-user-pass$/& $(basename ${2})/" "$1"
    printf "fix reference to user credentials... "
  fi
  nmcli connection import file "$1" type openvpn 2>&1 >/dev/null
  # fix missing vpn.data which nmcli did not export but are required
  nmcli connection modify "$(basename ${1%.ovpn})" +vpn.data "auth=SHA256"
  nmcli connection modify "$(basename ${1%.ovpn})" +vpn.data "ta-dir=1"
  # Add missing username and password for vpn connection
  if [ -f "$2" ]; then
    printf "Setting password + username... "
    nmcli connection modify "$(basename ${1%.ovpn})" +vpn.data username="$(head -n 1 "$2")"
    nmcli connection modify "$(basename ${1%.ovpn})" +vpn.secrets password="$(sed '2q;d' "$2")"
  else
    printf "Skipping setting password + username... "
  fi
  printf " done.\n"
  return 0
}

## import openvpn ovpn file if present on usb disk and was not installed before.
# 
# Some notes about how to restore an ovpn connection (Network Manager / cmdline)
#
# OpenVPN connection information - file format:
#   * One or more ovpn files are embedded in a tar.bz2 archive.
#   * For each ovpn file, there may be a accompanied file with the extension
#     .txt and contains username on line 1 and password as plaintext on line 2
#   * If the accompanied file is present, then there should also be an entry in
#     the ovpn file, referring to this file. This looks like:
#
#       auth-user-pass vpnconnect-UDP4-1194-manager-config.txt
#
#   * The command to import the ovpn connection into the network manager seems
#     to ignore the username and password stanza. When starting the connection
#     from the terminal, then username and password are correctly parsed and
#     used, meaning in that case it is not required for the user to enter the
#     vpn username and password separately. For the network manager, the trick
#     is to additionally provide the username and password separately, like:
#
#       nmcli connection import file "${CONN}.ovpn" type openvpn
#       # fix missing password settings which nmcli did not import
#       nmcli connection modify "${CONN}" +vpn.data username=manager
#       nmcli connection modify "${CONN}" +vpn.secrets "password=MYSECRET"
#       # fix missing vpn.data which nmcli did not export but are required
#       nmcli connection modify "${CONN}" +vpn.data "auth=SHA256"
#       nmcli connection modify "${CONN}" +vpn.data "ta-dir=1"
#
#     When starting the vpn connection from the command line, username and
#     password are used from the entry (as already shown above):
#
#       auth-user-pass ${CONN}.txt
#
#     Using following command:
#
#       sudo openvpn --config "${CONN}.ovpn"
#
#     will fail with the nmcli exported ovpn file. The reason is that there are
#     two required entries which need to be added to the ovpn file. These are:
#
#       auth SHA256
#       key-direction 1
#
# If the ovpn configuration was already installed, it does not re-install.
#
# provide on a usb stick an ovpn configuration with the following file name:
#   YOUR_VPN_CONNECTION_AS_IT_SHOWS_IN_NETWORK_MANAGER.ovpn.tar.bz2
#
# In this archive you can place two files:
#
#   YOUR_VPN_CONNECTION_AS_IT_SHOWS_IN_NETWORK_MANAGER.ovpn  <- created using
#                                                               openvpn export
#                                                               as ovpn inline
#                                                               option.
#   YOUR_VPN_CONNECTION_AS_IT_SHOWS_IN_NETWORK_MANAGER.txt (optional)
#
# Where YOUR_VPN_CONNECTION_AS_IT_SHOWS_IN_NETWORK_MANAGER.txt contains user on
# line 1 and password as plaintext on line 2. And should match settings at the
# openvpn server for that connection/user.
#
# If the .txt file is missing, network manager (and/or) openvpn will ask for the
# user and password instead.
#
# To extract and prepare the ovpn file with the username and password from an
# existing configuration, use:
#
#   nmcli --show-secrets connection show "${CONN}" | grep vpn.user-name | awk '{print $2}' > pass.txt
#   nmcli --show-secrets connection show "${CONN}" | grep vpn.secrets | sed 's/^.*password = //' >> pass.txt
#
# Then, for a new system, import the ovpn file in the network manager, with:
#
#   nmcli connection import file "${CONN}.ovpn" type openvpn 
#
# Because the network manager does not use the username and password as given in
# the ovpn file, it needs to be added separately with:
#
#   nmcli connection modify "${CONN}" vpn.secrets password="$(sed '2q;d' pass.txt)"
#   nmcli connection modify "${CONN}" vpn.user-name "$(head -n 1 pass.txt)"
#
# To troubleshoot, use the command line to invoke a vpn connection (which may
# use username and password from the additional file) with following command:
#
#   sudo openvpn --config "${CONN}.ovpn"
#
# Deleting a profile: nmcli connection delete "${CONN}"
# Importing a profile: nmcli connection import file "${CONN}.ovpn" type openvpn
# nmcli connection modify "${CONN}" vpn.user-name "USERNAME"
# nmcli connection modify "${CONN}" vpn.secrets password="MYSECRETPASSWORD"
# exporting a profile: nmcli con export <NAME>
#
# Issue:
# - no VPN connection status icon shown  -> sudo strace -f -t -e trace=file -p <PID>
#
# References:
# * https://superuser.com/questions/1695347/network-manager-store-secrets-for-automatic-openvpn-connection
# * https://serverfault.com/questions/483941/generate-an-openvpn-profile-for-client-user-to-import
# * https://networkmanager.dev/docs/api/latest/nmcli.html
# * https://gist.github.com/qiwichupa/2c1828232fd23258aeb78ac3808bd729  <-- script to export as ovpn with inline configuration
# * https://superuser.com/questions/1695347/network-manager-store-secrets-for-automatic-openvpn-connection
# * https://www.reddit.com/r/archlinux/comments/r1885f/etcnetworkmanagersystemconnections_is_blank/
# * https://bugs.launchpad.net/ubuntu-mate/+bug/1876467
# $1: filename of VPN_ARCHIVE on mounted volume (previously MNTF/BSFN)
import_all_vpn_connections () {
  printf ">>>> ATTENTION: archive $(basename -- "$1") found.\nTrying to import following connections:\n"
  WORK_DIR=$(mktemp -d -p "/tmp")
  tar xjf "$1" -C ${WORK_DIR}
  for VPN_CONN in $(find "${WORK_DIR}" -maxdepth 1 -type f -name "*.ovpn"); do
    printf "  - $(basename ${VPN_CONN%.ovpn})... "
    if ! nmcli --terse --fields name connection | grep -q "$(basename ${VPN_CONN%.ovpn})"; then
      # If .txt file available, then also import username and password
      openvpn_import "${VPN_CONN}" "${VPN_CONN%.ovpn}.txt"
      if [ "$?" != 0 ]; then
        printf "error... "
      fi
    else
      printf "skipping. already imported.\n"
    fi
  done
  rm -Rf "${WORK_DIR}"
  printf "Done.\n"
  return 0
}


# $1: mountpoint for file on USB drive containing full path and filename
export_all_vpn_connections () {
  # Create a temporary archive for extracted vpn connections
  TMP_DIR=$(mktemp -d)
  trap rm_tmp INT
  echo "Searching for available openvpn connections..." 
  for conn in $(nmcli --fields TYPE,NAME  connection show  | grep vpn |  awk -F' '  '{print $NF}'); do
    if [ -n "${conn}" ]; then
      printf "  - ${conn}... exporting... "
      targetname="$(echo "${conn}" | sed 's/[^0-9a-zA-Z.-]/_/g')"
      openvpn_export "${conn}" "${TMP_DIR%/}/${targetname}.ovpn"
      # create file with username and password for ovpn connection
      # from vpn.data extract username from '... ta-dir = 1, username = A.Dent, verify-x509-name ...'
      nmcli --show-secrets connection show "${conn}" | grep vpn.data | sed 's|.*username = \(.*\),.*|\1|' > "${TMP_DIR%/}/${targetname}.txt"
      nmcli --show-secrets connection show "${conn}" | grep vpn.secrets | sed 's/^.*password = //' >> "${TMP_DIR%/}/${targetname}.txt"
      # add filename with username and password into ovpn file
      sed -i "s|^\(auth-user-pass\)$|\1 ${targetname}.txt|" "${TMP_DIR%/}/${targetname}.ovpn"
      printf "Done.\n"
    fi
  done

  # Create tar archive for ovpn files and write to USB drive
  cd "${TMP_DIR}"
  tar cjf "$1" *.ovpn *.txt 
  echo "... created archive: $1"
  rm_tmp
  trap - INT
  printf "Done\n"
  return 0
}
