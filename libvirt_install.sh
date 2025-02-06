#!/bin/sh
#
# This script installs libvirt virtual machine manager
# configures it with a provided tar.bz2 archive containing
# domain, pool, libvirtd.conf and SLIC file
# It also install samba and adds one share
#
# References:
# https://gist.github.com/fsworld009/5f0ff0c5541079c4d28bdbc692fc15cf
# https://gist.github.com/xrobau/d98fe46c4677e46577ba2f20f35b783b
# https://stackoverflow.com/questions/28712839/domain-requires-kvm-but-it-is-not-available-check-that-virtualization-is-enabl
#
# Make sure to check in bios security virtualization settings if properly setup.
#
# Invoke this script by providing a tar.bz2 archive as argument.
#
# created by Marc Nijdam, Feb. 2025
#
# license: MIT

if [ $# != 1 ]; then
  echo "please provide a url for downloading the configuration"
else
  libvconf="$(basename -- "$1")"
fi


QEMU_USER="$(whoami)"
# samba user and password
SMB_USER="$(whoami)"
SMB_PWD="$(tr -dc A-Z0-9_ < /dev/urandom | head -c 10 | xargs)"
# local samba share location. Note that the last part is the root
# of the share as seen in windows. Windows will not show this name.
# This means that the path in windows is something like \\IP\$SMB_USER
#
# So whatever is stored in \\IP\$SMB_USER, lands in /shares/samba
SMB_SHARE="/shares/samba"


# samba configuration
smbconf="/etc/samba/smb.conf"
# install libvirt and qemu dependencies 
sudo apt-get update && sudo apt-get -y install qemu-kvm virt-manager \
                            libvirt-daemon-system libvirt-clients bridge-utils \
                            virtinst


## download virt settings
if [ ! -f "$HOME/Downloads/${libvconf}" ]; then
  wget -O "$HOME/Downloads/${libvconf}" "$1"
else
  echo "not downloading ${libvconf}, because it is already present."
fi

# extract and identify files from provided tar.bz2 file
tmpdir=$(mktemp -d)
tar xjf "$HOME/Downloads/${libvconf}" -C $tmpdir
cd $tmpdir
virt_domain=$(grep -l "^<domain" *)
virt_stor=$(grep -l "^<pool" *)
virt_lvrtd="libvirtd.conf"
virt_slic="SLIC"
domain_name="$(sed -n 's|[^<]*<name>\([^<]*\)</name>[^<]*|\1\n|gp' "${virt_domain}")"
echo "The following files were found:"
echo "  domain: $virt_domain"
echo "  storage: $virt_stor"
echo "  libvirtd configuration: libvirtd.conf"
echo "  SLIC file: SLIC"


## check if directories are present
printf "verifying if directories are present ... \n"
[ -d "/etc/libvirt/" ] || { echo "libvirt settings directory missing. Aborting..."; exit 1; }
[ -d "/etc/libvirt/qemu/" ] || { echo "libvirt qemu settings directory missing. Aborting..."; exit 1; }
sudo [ -d "/var/lib/libvirt/qemu/nvram/" ] || { echo "libvirt qemu nvram directory missing. Aborting..."; exit 1; }
sudo mkdir -p /etc/libvirt/storage/
printf "Done\n"


## move files to corresponding places
# except for SLIC, all are stored as root:root SLIC has libvirt-qemu:kvm
printf "copying configuration files to corresponding locations ... \n"
if [ -f "/etc/libvirt/${virt_lvrtd}" ]; then
  echo "overwriting /etc/libvirt/${virt_lvrtd}"
fi
sudo mv "${tmpdir%/}/${virt_lvrtd}" /etc/libvirt/
sudo chown root:root "/etc/libvirt/${virt_lvrtd}"
#
if [ ! -f "/etc/libvirt/qemu/${virt_domain}" ]; then
  sudo cp "${tmpdir%/}/${virt_domain}" /etc/libvirt/qemu/
  sudo chown root:root "/etc/libvirt/qemu/${virt_domain}"
else
  echo "skipping /etc/libvirt/qemu/${virt_domain}"
fi
#
if [ ! -f "/etc/libvirt/storage/${virt_stor}" ]; then
  sudo mv "${tmpdir%/}/${virt_stor}" /etc/libvirt/storage/
  sudo chown root:root "/etc/libvirt/storage/${virt_stor}"
else
  echo "skipping /etc/libvirt/storage/${virt_stor}"
fi
#
if ! sudo test -f "/var/lib/libvirt/qemu/nvram/${virt_slic}"; then
  echo "overwriting /var/lib/libvirt/qemu/nvram/${virt_slic}"
fi
sudo mv ${tmpdir%/}/${virt_slic} /var/lib/libvirt/qemu/nvram/
sudo chown libvirt-qemu:kvm "/var/lib/libvirt/qemu/nvram/${virt_slic}"
printf "Done\n"


## allow virt-manager as non-root user
# After adding the user libvirt, it would be necessary for the group membership
# changes to propagate into the current session. The command newgrp libvirt
# could be a solution, but has the drawback that one additional session is
# created.
# https://askubuntu.com/questions/345218/virt-manager-cant-connect-to-libvirt
if ! sudo getent group | grep -q libvirt; then
  printf "Add group libvirt ... "
  sudo usermod -a -G libvirt $(whoami)
  # newgrp libvirt
  printf "Done\n"
else
  printf "group libvirt was already added... \n"
fi


## restart libvirtd
sudo systemctl restart libvirtd.service


## import system if it is not there
# https://serverfault.com/questions/1002043/libvirt-has-no-kvm-capabilities-even-though-qemu-kvm-works
if ! virsh list --all | grep -q "${domain_name}"; then
  virsh define --file "${tmpdir%/}/${virt_domain}"
else
  printf "domain was already added to libvirt... \n"
fi
rm -Rf "${tmpdir}"


# https://ostechnix.com/solved-cannot-access-storage-file-permission-denied-error-in-kvm-libvirt/
sudo sed -i "/^#user =/s/.*/user = \"${QEMU_USER}\"/" /etc/libvirt/qemu.conf
sudo sed -i '/^#group =/s/.*/group = "libvirt"/' /etc/libvirt/qemu.conf
sudo systemctl restart libvirtd


## Test activation status for windows
# start via command line using:
#   virt-manager
# Or start via plank, typing: virtual machine manager
# after starting windows, you can verify the activation status with:
#   slmgr /xpr
# It should respond with:
#    Windows(R), Professional edition
#      The machine is permanently activated. 


### samba file sharing

## install samba file sharing
sudo apt-get -y install samba-common samba


## set rules for firewall
if ! sudo ufw app list | grep -q Samba; then
  sudo ufw allow 'Samba'
else
  printf "firewall rule for Samba was already added.\n" 
fi


## configure smb.conf
# add each line after match, but only if it is not already there 
grep -qe '^interfaces' "${smbconf}" || sudo sed -i '/^;.*interfaces = 127.0.0.0/a interfaces = virbr0' "${smbconf}"
grep -qe '^bind interfaces only' "${smbconf}" || sudo sed -i '/^;.*bind interfaces only/a bind interfaces only = yes' "${smbconf}"


## create directory for smb share and change ownership outside of user profile
# this is untested with chains of multiple directories. e.g. /home/user/samba
# but for two adjacent directories it works, like in: /shares/samba
if [ ! -d "${SMB_SHARE}" ]; then
  sudo mkdir -p ${SMB_SHARE%/*}
  sudo chgrp -R sambashare ${SMB_SHARE%/*}
  cd ${SMB_SHARE%/*}
  sudo mkdir $(basename ${SMB_SHARE})
  sudo chown $(whoami):sambashare $(basename ${SMB_SHARE})
  sudo chmod 2770 $(basename ${SMB_SHARE})
else
  printf "host directory for sharing files with guest was already added\n"
fi


## add and enable user $SMB_USER
if ! sudo pdbedit -L -v -u "${SMB_USER}" 2> /dev/null | grep -q '^Account Flags:.*U' > /dev/null; then
  (echo "${SMB_PWD}"; sleep 1; echo "${SMB_PWD}" ) | sudo smbpasswd -s -a "${SMB_USER}" >/dev/null
  sudo smbpasswd -e "${SMB_USER}" >/dev/null
else
  printf "user ${SMB_USER} was already added and enabled\n"
fi


## add share to samba
# allow symlinks to be used as share
if ! grep -qe "^\[${SMB_USER}\]" "${smbconf}"; then
  histchars=
  q="[${SMB_USER}]\n"
  q="$q    path = ${SMB_SHARE}\n"
  q="$q    browseable = no\n"
  q="$q    read only = no\n"
  q="$q    follow symlinks = yes\n"
  q="$q    wide links = yes\n"
  q="$q    force create mode = 0660\n"
  q="$q    force directory mode = 2770\n"
  q="$q    valid users = ${SMB_USER}"
  # replace \n with newline and write to xml
  printf "\n${q}\n" | sudo tee -a "${smbconf}" >/dev/null
  unset histchars
else
  printf "samba share ${SMB_SHARE} was already added\n"
fi


## restart nmbd, stop smbd. The latter will start automatically when qemu starts
sudo systemctl restart nmbd
sudo systemctl stop smbd


## add hook for qemu, to start smbd only of qemu is started
[ -d /etc/libvirt/hooks/ ] || sudo mkdir -p /etc/libvirt/hooks/
cd /etc/libvirt/hooks/
if [ ! -f /etc/libvirt/hooks/qemu ]; then
  histchars=
  q='#!/bin/sh\n'
  q=$q'GUEST_NAME="XGUEST"\n'
  q=$q'if [ "$1" = $GUEST_NAME ]; then\n'
  q=$q'  if [ "$2" = "start" ]; then\n'
  q=$q'    systemctl restart smbd\n'
  q=$q'  elif [ "$2" = "stopped" ]; then\n'
  q=$q'    systemctl stop smbd\n'
  q=$q'  fi\n'
  q=$q'fi'
  printf "${q}\n" | sed 's/\\n/\'$'\n''/g' | \
        sed "s|XGUEST|${domain_name}|" | \
        sudo tee /etc/libvirt/hooks/qemu >/dev/null
  unset histchars
  sudo chmod +x /etc/libvirt/hooks/qemu
else
  printf "qemu hook for samba was already added\n"
fi


## done! show summary
histchars=
q="====================================\n"
q="${q}virtual machine manager is installed\n\n"
q="${q}samba file sharing is installed\n"
q="${q}  network share: $SMB_SHARE\n"
q="${q}  password: $SMB_PWD\n\n"
q="${q}PLEASE RESTART YOUR SYSTEM FIRST BEFORE\n"
q="${q}USING KVM/QEMU.\n\n"
q="${q}Then start windows and your network share\n"
q="${q}should be drive Z: (or any other drive name)\n"
q="${q}If not, configure in windows:\n"
q="${q}1. right click on Network → Map network drive\n"
q="${q}2. Enter following data:\n"
q=${q}'      Drive: Z\n      Folder: \\\\192.168.122.1\\'
q="${q}${SMB_USER}\n"
q="${q} (Note that the absolute path is still ${SMB_SHARE})\n"
q="${q}      enable Reconnect at sign-in\n"
q="${q}      enable Connect using different credentials\n"
q="${q}3. In the next window, enter the username and password\n"
q="${q}   and click on the option remember.\n"
q="${q}You are done. Now the network should appear."
printf "${q}\n" | sed 's|\\n|\'$'\n''|g' | tee $HOME/samba_summary.txt
unset histchars
