#!/bin/false
# This file contains a csv-like list with filenames and other data which is used
# by a post-install.sh script for configurating and setting up freshly installed
# Ubuntu-MATE installation. The filenames in this list refer to files which
# reside on a web-server. Upon invoking the post-install.sh script, each file
# is download if it is not already present on the system. This allows to run the
# post-install.sh script multiple times.

# This file lists modules which should be present on a webserver.
# The name of this file should be:
#   post_install_modules_list.sh
#
# The format can be:
#   "KEY";"FILE";"DESCRIPTION"
# or just
#   "FILE"
# without KEY and DESCRIPTION if it should not be displayed in a menu, but still
# be downloaded from the webserver.
#
# KEY defines the keyboard shortcut.
# FILE defines the filename of a shell script which takes no arguments and may
# return 1 in case of an error.
# DESCRIPTION defines a description as shown to the user menu.
#
# There shall be no secrets stored in any of these files.
#
# Files which are numbered from 00000 through 00099 are designated for global
# variables.
#
# Empty lines or lines starting with # are ignored.
"";"00000.global_variables.sh";""
"";"00001.function_library.sh";""
"";"00005.vpn_import_export.sh";""
"";"00050.patch_xserver-xorg-core.sh";""
"";"00051.create_freecad_launcher.sh";""
"";"00052.libvirt_install.sh";""
"";"00053.patch_mate-notification-daemon.sh";""
"b";"00980.backup_installation.sh";"backup: ~/backup, ~/.ssh, ~/.mozilla, vmail, Maintenance and evolution"
"X";"00880.prepare_system.sh";"prepare system for (re)-installation, overwriting disk storage"
"h";"11040.change_hostname.sh";"change hostname on this machine"
"k";"11070.install_sshkeys.sh";"install private and public key from file sshkeys.tar.bz2 from USB"
"n";"11100.calculate_new_ssh_identity.sh";"create new ssh identity and upload for domains on domains.csv from USB"
"s";"11150.disable_snapd_and_install_firefox.sh";"replace firefox snap with deb and disable snapd"
"u";"11170.update_upgrade_apt.sh";"upgrade apt system packages"
"0";"20450.restore_directories.sh";"restore directories (backup and Maintenance) from usb drive"
"1";"20480.system_functional_changes.sh";"make functional changes to the system like vi, directories etc."
"2";"20490.install_and_setup_password_manager.sh";"install and setup password manager, using passwords.tar.bz2 from USB"
"3";"20500.install_firefox_profile.sh";"install firefox profile from provided mozilla.profile.tar.bz2 from USB"
"4";"20510.setup_dovecot.sh";"setup local dovecot mail server and extract vmail.tar.bz2 from USB"
"5";"20520.setup_evolution.sh";"setup evolution mail client using evolution-backup-YYYYMMDD from USB"
"6";"20530.setup_ubuntu_unity.sh";"configure user interface to ubuntu unity-alike"
"7";"20540.install_common_software.sh";"install common software (Inkscape, gimp, libreoffice etc.)"
"8";"20550.restore_files_from_archives.sh";"restore files which were archived"
"p";"21120.change_system_passwords.sh";"change password for current user + root and change luks passphrase"
