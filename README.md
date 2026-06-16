# System backup/installation/setup scripts

This repository contains shell scripts for (ubuntu) linux to make the initial steps during installation of the operating system easier.

Target distribution: ubuntu 24.04 (mate)

Please see the header of the scripts to understand what it is for.

It was initially created for the following main reasons:
* Make sure that the touchpad uses preferred settings like twi finger natural scrolling right from the beginning after logging in the very first time. This was partly achieved using an autoinstall.yaml file and after that letting the post_install script take over settings which require a graphical user interface to be present (using gsettings).
* Replicate the (global menu) unity desktop as good as possible it was in Ubuntu 20.04 combining the OSX-like "eleven" user layout with the Ambiant-MATE-Dark theme.

With this solved, the collection of scripts gradually became larger to configure all kind of settings and configurations which required more complicated sequence of steps to perform.

The scripts as such are tailored for a specific setup. But the individual solutions in the scripts maybe still valuable for other users. For example automatically setting up dovecot as a local imap server to store archived mails and creating an additional read-only mail account to access these archived mails (per mail sharing with read-only permissions) involved many steps. It also disables snap automatically, uninstalls the existing snap  packages and makes sure no snap package will be installed afterwards.

# Usage
In order to use the scripts, either copy all files ending with .sh (or copy only the following two files) to $HOME/install/
* ```post_install.sh```
* ```post_install_modules.sh```

After making post_install.sh executable with:

```chmod +x post_install.sh```

The script can be executed with:

```./post_install.sh```

It will then try to download any missing files from the ones listed in post_install_modules_ist.sh. It will then display a menu which helps with consistently creating a backup/installation/setup of one computer system to another computer system.

The menu will look like the following:
```
==== (pre)post-installation options ====
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Pre-installation options:
  b. backup: ~/backup, ~/.ssh, ~/.mozilla, vmail, Maintenance and evolution
  X. prepare system for (re)-installation, overwriting disk storage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Post-installation essential steps:
  h. change hostname on this machine
  k. install private and public key from file sshkeys.tar.bz2 from USB
  n. create new ssh identity and upload for domains on domains.csv from USB
  s. replace firefox snap with deb and disable snapd
  u. upgrade apt system packages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Post-installation optional steps:
  0. restore directories (backup and Maintenance) from usb drive
  1. make functional changes to the system like vi, directories etc.
  2. install and setup password manager, using passwords.tar.bz2 from USB
  3. install firefox profile from provided mozilla.profile.tar.bz2 from USB
  4. setup local dovecot mail server and extract vmail.tar.bz2 from USB
  5. setup evolution mail client using evolution-backup-YYYYMMDD from USB
  6. configure user interface to ubuntu unity-alike
  7. install common software (Inkscape, gimp, libreoffice etc.)
  8. restore files which were archived
  p. change password for current user + root and change luks passphrase
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  q. quit
Select option:
```

And should provide sufficient guidance to perform the required steps.
