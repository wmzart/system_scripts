#!/bin/sh
TU="$(whoami)"
DEF_PASWD="ubuntu"

APPDIR="$HOME/Maintenance/apps/"

## directory in profile where files and directories are which really need backup
NEW_PROFILE_DIR="backup"

## backup sources
SSH_ARCHIVE="sshkeys.tar.bz2"
MOZ_ARCHIVE="mozilla.profile.tar.bz2"
VML_ARCHIVE="vmail.tar.bz2"
EVO_ARCHIVE="evolution-backup-"
VPN_ARCHIVE="vpn_connections-"
PSW_ARCHIVE="passwords.tar.bz2"

## psafe3 password manager
PSAFEKEY_DIR=".local/share/keyrings"
# ID to search for in $SECRETS_FILE on USB stick
PWSAFE_DMN_ID="DOMAIN_PWSAFE"

# common dovecot settings
DUSRID=10000
DDOMAIN=localstor
DUSRGRP=vmail
DRO_USER=readonly

## file on USB disk with secrets which may be used to enhance the functionality
SECRETS_FILE="secrets.csv"

# ssh accessible servers which may need ssh keys to be updated
SSH_ACCESS_SRV_ID="REMOTE_SERVERS"
