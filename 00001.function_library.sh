#!/bin/sh

# collection of helper functions which are used in conjunction with the
# backup/(re)installation scripts.
#
# created by Marc Nijdam, Dec. 2025
#
# License: MIT

# TESTMODE=1 means instead of the mounted drive a local directory install/USB_DRIVE is used
# TESTMODE=1

# remove tmp dir, used in combination with the trap command
rm_tmp () {
  if [ -d "${TMP_DIR}" ]; then
    rm -rf "${TMP_DIR}"
  fi
}


# https://stackoverflow.com/questions/5866767/shell-script-sudo-permissions-lost-over-time
# https://unix.stackexchange.com/questions/269078/executing-a-bash-script-function-with-sudo
# https://serverfault.com/questions/177699/how-can-i-execute-a-bash-function-with-sudo
startsudo() {
  if [ -z "$SUDO_PID" ]; then
    echo ">>    The following steps require root. Please enter password (hint: ubuntu):"
    sudo -v
    ( while true; do sudo -v; sleep 50; done; ) &
    SUDO_PID="$!"
    # for sh shell, use INT instead of SIGINT and TERM instead of SIGTERM
    trap stopsudo INT TERM
  fi
}


stopsudo() {
  if [ -n "$SUDO_PID" ]; then
    kill "$SUDO_PID"
    # for sh shell, use INT instead of SIGINT and TERM instead of SIGTERM
    trap - INT TERM
    sudo -k
    SUDO_PID=""
  fi
} 


# If provided string starts with a #-character, return 1, if not, return 0
check_if_comment_line () {
  if [ "$(echo $1 | cut -c1-1)" = "#" ]; then
    return 1
  fi
  return 0
}


# If remote file exists, return 1, if not, return 0
validate_url () {
  if wget -S --timeout=5 --spider $1  2>&1 | grep -q 'Length: unspecified'; then
    return 1
  fi
  return 0
}


# Download archive file from a given location and extract to temporary location
# $1 full path for download location including target file
# $2 informational text to be displayed about the download
#
# If .tar.bz2 or .zip file, extract and remove the file when done.
download_and_extract () {
  ARCHV="$(basename "$1")"
  if [ ! -e "/tmp/${ARCHV}" ]; then
    printf ">>    downloading $2 install script ${ARCHV} archive ...\n"
    wget_result="$(wget -S --max-redirect=0 -O "/tmp/${ARCHV}" "$1" 2>&1|grep "HTTP/"|awk '{print $2}')"
    if [ "$wget_result" != "200" ]; then
      return 1
    fi
  else
    printf ">>    $2 archive ${ARCHV} already there ...\n"
  fi

  cd /tmp
  # check for lowercase 
  case "$(echo ${ARCHV} | tr '[:upper:]' '[:lower:]')" in
    *.tar.bz2)
      tar xjf "/tmp/${ARCHV}"
      BNAME="/tmp/${ARCHV%.[Tt][Aa][Rr].[Bb][Zz]2}"
      ;;
    *.zip)
      unzip "/tmp/${ARCHV}"
      BNAME="/tmp/${ARCHV%.[Zz][Ii][Pp]}"
      ;;
    *)
      BNAME=""
      return 1
      ;;
  esac
 
  return 0  
}


# Get mounted drive by optionally specifying file and searching for it
# $1 (optional) file to search for
# $2 (optional) quiet (do not show any warnings), anything else (show warnings)
# returns 1 on error, 0 on all OK
# return variable: MNTF for mountpoint and BSFN for basename
get_mounted_drive () {
  if [ ! -z "$1" ]; then
    echo "trying to find if a USB drive is connected..."
    if [ -z "${HOME#/home/}" ]; then
      echo "cannot find USB drive if user is not specified: \$${HOME#/home/} undefined"
      return 0
    fi
    if [ -n "${TESTMODE}" ]; then
      MNTF="$HOME/install/USB_DRIVE"
    else
      MNTF=$(mount | grep "/media/${HOME#/home/}" | head -n 1 | awk '{print $3}')
    fi

    if [ -z "${MNTF}" ]; then
      if [ $# = 1 -o $# = 2 -a "$2" != "quiet" ]; then
        echo "unable to find USB drive. Is it connected?"
      fi
      return 1
    fi
    BSFN=""
    if [ -n "${TESTMODE}" ]; then
      MNTF=$(find "$HOME/install/USB_DRIVE" -maxdepth 2 -type f -name "$1" | sort | tail -n 1)
    else
      MNTF=$(find "/media/${HOME#/home/}" -maxdepth 2 -type f -name "$1" | sort | tail -n 1)
    fi
    if [ ! -f "${MNTF}" ]; then
      if [ $# = 1 -o $# = 2 -a "$2" != "quiet" ]; then
        echo "unable to find file $1 on USB drive. Is the file present?"
      fi
      return 1
    fi
    BSFN="$(basename "${MNTF}")"
    MNTF="$(dirname "${MNTF}")"
  else
    if [ -n "${TESTMODE}" ]; then
      MNTF="$HOME/install/USB_DRIVE"
    else
      MNTF=$(mount | grep "/media/${HOME#/home/}" | head -n 1 | awk '{print $3}')
    fi
    if [ -z "${MNTF}" ]; then
      if [ $# = 1 -o $# = 2 -a "$2" != "quiet" ]; then
        echo "unable to find USB drive. Is it connected?"
      fi
      return 1
    fi
  fi
  return 0 
}


# Clean up archive and possibly extracted contents
# $1: archive file, either tar.bz2 or zip format.
# which were previously extracted to /tmp 
remove_archive_and_extracted_files () {
  ARCHV="$(basename "$1")"

  cd /tmp
  # check for lowercase 
  case "$(echo ${ARCHV} | tr '[:upper:]' '[:lower:]')" in
    *.tar.bz2)
      tar --list -f "/tmp/${ARCHV}" | while IFS= read -r fname; do
        rm -Rf "/tmp/${fname}"
      done
      ;;
    *.zip)
      unzip -Z1 "/tmp/${ARCHV}" | while IFS= read -r fname; do
        rm -Rf "/tmp/${fname}"
      done
      ;;
    *)
      echo "unsupported archive format. ignoring deletion"
      return 1
      ;;
  esac

  [ -e "/tmp/${ARCHV}" ] && rm "/tmp/${ARCHV}"

  return 0  
}


# Lookup a string in a csv-type file by specifying column and identifier (ID)
# $1: identifier to search for
# $2: source file on main folder
# $3: column to return (1, 2 or 3)
# RETVAL: result from search
# Current limitation is that it only search for the first hit. This may cause a
# problem if there are multiple similar lines from which one is a comment line.
# return value: 1 String found, 0: not found
lookup_field () {
  RETVAL=""
  if [ -z "$1" ] || [ -z "$2" ]; then
    return 0
  fi
  HIT=$(grep "$1" "$2")
  check_if_comment_line "${HIT}"
  if [ "$?" != 0 ]; then
    return 0
  fi
  RETVAL=$(echo ${HIT} | sed "s/\"\(.*\)\";\"\(.*\)\";\"\(.*\)\"/\\$3/")
  if [ -z "${RETVAL}" ]; then
    return 0
  fi
  return 1
}
