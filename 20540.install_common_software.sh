#!/bin/sh

# This module will install following programs:
#   Gimp
#   Inkscape
#   libreoffice + dependencies
#   winrar
#   vuescan
#   cheese
#   qpdf + pdftk
#   bbe
 

# Author: Marc Nijdam, 2025
# License: MIT
#

## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done


# https://gist.github.com/h1romas4/8d2c3584a49b86350f5010d3fc94f010
##
install_common_sw () {
  echo ">>>> ATTENTION: ABOUT TO INSTALL COMMON SOFTWARE. READ CAREFULLY!"
  echo ">>    Installing: Gimp, Inkscape, libreoffice, libreoffice dependencies,"
  echo ">>    rar and vuescan."
  startsudo
  if dpkg -l gimp 2>&1 | grep -q "ii"; then
    printf ">> Gimp already installed...\n"
  else
    printf ">> Installing gimp...\n"
    sudo add-apt-repository -y ppa:ubuntuhandbook1/gimp-3
    sudo apt-get -y install gimp
    printf ">> Done.\n"
  fi
  #
  if dpkg -l inkscape 2>&1 | grep -q "ii"; then
    printf ">> Inkscape already installed...\n"
  else
    printf ">> Installing inkscape...\n"
    sudo add-apt-repository -y ppa:inkscape.dev/stable
    sudo apt-get -y install inkscape
    printf ">> Done.\n"
  fi
  # native libreoffice on mate does not show a global menu. gnome version solves this.
  # https://ask.libreoffice.org/t/new-upgrade-wont-open-odt-files-in-mint-21-1/88151
  if dpkg -l libreoffice-gnome 2>&1 | grep -q "ii"; then
    printf ">> Libreoffice dependencies already installed...\n"
  else
    printf ">> Installing libreoffice dependencies...\n"
    sudo apt-get -y install default-jre libreoffice-java-common libreoffice-gnome
    printf ">> Done.\n"
  fi
  if dpkg -l libreoffice-writer 2>&1 | grep -q "ii"; then
    printf ">> Libreoffice suite already installed...\n"
  else
    printf ">> Installing full libreoffice suite...\n"
    sudo add-apt-repository -y ppa:libreoffice/ppa
    sudo apt update
    sudo apt-get -y install libreoffice
    printf ">> Done.\n"
  fi
  # install vuescan
  if dpkg -l vuescan 2>&1 | grep -q "ii"; then
    echo ">>    vuescan already installed"
  else
    echo ">>    Installing: vuescan"
    echo "  - Fetching latest version for linux from www.hamrick.com"
    LATEST_VUESCAN="https://www.hamrick.com/$(wget -qO- https://www.hamrick.com/alternate-versions.html | sed -z 's#.*<a href="\(files/vuex[[:digit:]]\+\.*deb\).*#\1##')"
    echo "  - Downloading $(basename "${LATEST_VUESCAN}")"
    wget -q --show-progress -O "/tmp/$(basename "${LATEST_VUESCAN}")" "${LATEST_VUESCAN}" 2>&1
    sudo apt-get -y install "/tmp/$(basename "${LATEST_VUESCAN}")" && rm "/tmp/$(basename "${LATEST_VUESCAN}")"
    echo ">>    Done."
  fi
  # install rar
  if [ ! -f /usr/local/bin/rar -o ! -f /usr/local/bin/unrar ]; then
    echo ">>    Installing: rar"
    echo "  - Fetching latest version for linux from www.win-rar.com"
    LATEST_WINRAR=$(wget -qO- https://www.win-rar.com/download.html | sed -z 's#.*\(https://www.win-rar.com/fileadmin/winrar-versions/rarlinux.*tar.gz\).*for Linux English 64 bit.*#\1##')
    echo "  - Downloading $(basename "${LATEST_WINRAR}")"
    wget -q -O "$TMP_DIR/$(basename "${LATEST_WINRAR}")" "${LATEST_WINRAR}" 2>&1
    tar xzf $(basename "${LATEST_WINRAR}") && sudo mv rar/rar rar/unrar /usr/local/bin/
    echo ">>    Done."
  else
    echo ">>    rar already installed"
  fi
  # install cheese
  if dpkg -l cheese 2>&1 | grep -q "ii"; then
    printf "cheese already installed.\n"
  else
    printf "Installing cheese...\n"
    sudo apt-get -y install cheese
    printf "Done.\n"
  fi
  # install qpdf
  if dpkg -l qpdf 2>&1 | grep -q "ii"; then
    printf "qpdf already installed.\n"
  else
    printf "Installing qpdf...\n"
    sudo apt-get -y install qpdf
    printf "Done.\n"
  fi
  # install pdftk
  if dpkg -l pdftk 2>&1 | grep -q "ii"; then
    printf "pdftk already installed.\n"
  else
    printf "Installing pdftk...\n"
    sudo apt-get -y install pdftk
    printf "Done.\n"
  fi
  # install bbe
  if dpkg -l bbe 2>&1 | grep -q "ii"; then
    printf "bbe already installed.\n"
  else
    printf "Installing bbe...\n"
    sudo apt-get -y install bbe
    printf "Done.\n"
  fi


  # pdf studio
  # https://kbpdfstudio.qoppa.com/pdf-studio-command-line-installation-registration/
  
  # install sox, to be able to play music from the console using play *
  # but note there is a bug when using keyboard shortcut to change volume setting
  # it will stall the thinkpad special key loudspeaker icon. Workaround is to
  # change volume with the mouse via the panel volume settings (in the top).
  if dpkg -l sox 2>&1 | grep -q "ii"; then
    printf "sox already installed.\n"
  else
    printf "Installing sox...\n"
    sudo apt-get -y install sox
    printf "Done.\n"
  fi
  # install xclip
  if dpkg -l xclip 2>&1 | grep -q "ii"; then
    printf "xclip already installed.\n"
  else
    printf "Installing xclip...\n"
    sudo apt-get -y install xclip
    printf "Done.\n"
  fi
  
  stopsudo
  return 0
}

###############################
##
## >>>>> code entry below <<<<<

install_common_sw
