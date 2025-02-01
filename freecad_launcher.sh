#!/bin/sh

# Install xdg desktop item and associate file type with icon.
#
# Invoke this script without arguments, to installed the item, or
# invoke with the argument uninstall in order to remove the item.
#
# created by Marc Nijdam, Jan. 2025

## configurables
L_APP="$HOME/freecad/FreeCAD_1.0.0-conda-Linux-x86_64-py311.AppImage"
L_TGT="freecad"
L_NM="application-x-extension-fcstd"
L_MIME="application/x-extension-fcstd"
L_DESCR="FreeCAD document files"
L_EXT="fcstd"

## non-configurables
eval L_TM=$(gsettings get org.mate.interface icon-theme)


uninstall_launcher () {
  if [ -h "/usr/local/bin/${L_TGT}" ]; then
    cd /usr/local/bin
    sudo unlink "${L_TGT}"
  fi

  for size in 16 24 32 48 64 128 256; do
    # remove png in /usr/share/icons/hicolor/${size}x${size}/mimetypes
    sudo xdg-icon-resource uninstall --context mimetypes --size $size "${L_NM}"
    # remove png in /usr/share/icons/hicolor/${size}x${size}/apps
    sudo xdg-icon-resource uninstall --context apps --size $size "${L_NM}"
    # remove png in /usr/share/icons/$THEME/${size}x${size}/mimetypes
    sudo xdg-icon-resource uninstall --theme "${L_TM}" --context mimetypes --size $size "${L_NM}"
    # remove png in /usr/share/icons/$THEME/${size}x${size}/apps
    sudo xdg-icon-resource uninstall --theme "${L_TM}" --context apps --size $size "${L_NM}"
  done
  [ -d "/usr/share/icons/hicolor/scalable/apps/${L_NM}.svg" ] && sudo rm "/usr/share/icons/hicolor/scalable/apps/${L_NM}.svg"
  [ -d "/usr/share/icons/hicolor/scalable/mimetypes/${L_NM}.svg" ] && sudo cp "/usr/share/icons/hicolor/scalable/mimetypes/${L_NM}.svg"

  sudo gtk-update-icon-cache /usr/share/icons/*
  sudo update-mime-database /usr/share/mime
  sudo update-icon-caches /usr/share/icons/*
  
  sudo xdg-desktop-menu uninstall --novendor "${L_TGT}.desktop"
  sudo update-desktop-database /usr/share/applications
  
  sudo sed -i "\|^${L_MIME}|d" /etc/mime.types
  
  [ -d "/usr/share/mime/packages/${L_TGT}.xml" ] && sudo xdg-mime uninstall "/usr/share/mime/packages/${L_TGT}.xml"
  
}


# ==                                ==
# ====                            ====
# ====== CODE ENTRY POINT BELOW ======
# ====                            ====
# ==                                ==


# handle arguments
if [ "$#" = 1 -a "$1" = "uninstall" ]; then
    uninstall_launcher
    exit
fi


# check dependency imagemagick
if ! command -v convert 2>&1 >/dev/null; then
  printf "imagemagick missing. Please install with:\n  sudo apt-get install imagemagick imagemagick-doc\nAborting.\n"
  exit
fi

# check if svg and desktop file are present in ~/Downloads
[ -f "$HOME/Downloads/${L_TGT}.svg" ] || { echo "please provide an svg file in ~/Downloads  Aborting..."; exit; }
[ -f "$HOME/Downloads/${L_TGT}.svg" ] || { echo "please provide a desktop file in ~/Downloads  Aborting..."; exit; }


# check if symlink already exists...
if [ ! -h "/usr/local/bin/${L_TGT}" ]; then
  # create a symbolic link in /usr/local/bin/ pointing to our target application
  cd /usr/local/bin
  sudo ln -s "${L_APP}" "${L_TGT}"

  cd ~/Downloads/
  # Create and install different sizes for the svg icon
  # https://portland.freedesktop.org/doc/xdg-icon-resource.html
  # get theme and strip single quote around it using eval
  for size in 16 24 32 48 64 128 256; do
    # imagemagick works rasterbased, so make first a high resolution conversion, then scale down
    convert -background none -density 2000 -resize $size "${L_TGT}.svg" "${L_TGT}_${size}x${size}.png"
    # place png in /usr/share/icons/hicolor/${size}x${size}/mimetypes
    sudo xdg-icon-resource install --context mimetypes --size $size "${L_TGT}_${size}x${size}.png" "${L_NM}"
    # place png in /usr/share/icons/hicolor/${size}x${size}/apps
    sudo xdg-icon-resource install --context apps --size $size "${L_TGT}_${size}x${size}.png" "${L_NM}"
    # place png in /usr/share/icons/$THEME/${size}x${size}/mimetypes
    sudo xdg-icon-resource install --theme "${L_TM}" --context mimetypes --size $size "${L_TGT}_${size}x${size}.png" "${L_NM}"
    # place png in /usr/share/icons/$THEME/${size}x${size}/apps
    sudo xdg-icon-resource install --theme "${L_TM}" --context apps --size $size "${L_TGT}_${size}x${size}.png" "${L_NM}"
    # and remove again
    rm "${L_TGT}_${size}x${size}.png"
  done
  # copy scalable manually into apps and mimetypes
  sudo cp "${L_TGT}.svg" "/usr/share/icons/hicolor/scalable/apps/${L_NM}.svg"
  sudo cp "${L_TGT}.svg" "/usr/share/icons/hicolor/scalable/mimetypes/${L_NM}.svg"

  sudo gtk-update-icon-cache /usr/share/icons/*
  sudo update-mime-database /usr/share/mime
  sudo update-icon-caches /usr/share/icons/*

  ## install desktop file
  desktop-file-validate "${L_TGT}.desktop"
  sudo xdg-desktop-menu install --novendor "${L_TGT}.desktop"
  sudo update-desktop-database /usr/share/applications

  ## Edit the /etc/mime.types file. Add (for example) the following line (using TABs):
  # application/x-extension-fcstd			fcstd
  if ! grep -q -e "^${L_MIME}" /etc/mime.types; then
    echo -e "${L_MIME}\t\t\t${L_EXT}" | sudo tee -a /etc/mime.types >/dev/null
  fi

  ## create a file type description for mimetypes
  histchars=
  q='<?xml version="1.0" encoding="UTF-8"?>\n'
  q=$q'<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">\n'
  q=$q'	<mime-type type="XMIME">\n'
  q=$q'		<sub-class-of type="application/zip"/>\n'
  q=$q'		<comment>XDESCR</comment>\n'
  q=$q'		<glob pattern="*.XEXT"/>\n'
  q=$q'		<icon name="XNAME"/>\n'
  q=$q'	</mime-type>\n'
  q=$q'</mime-info>'
  # replace \n with newline and write to xml
  printf "${q}\n" | sed 's/\\n/\'$'\n''/g' > "${L_TGT}.xml"
  unset histchars
  # fill in relevant parts
  sed -i "s|XMIME|${L_MIME}|" "${L_TGT}.xml"
  sed -i "s|XDESCR|${L_DESCR}|" "${L_TGT}.xml"
  sed -i "s|XEXT|${L_EXT}|" "${L_TGT}.xml"
  sed -i "s|XNAME|${L_NM}|" "${L_TGT}.xml"
  # install xml to /usr/share/mime/packages/
  sudo xdg-mime install --novendor "${L_TGT}.xml"

  ## associate filetype and update the mime database
  xdg-mime default "${L_TGT}.desktop" "${L_MIME}"

  rm "${L_TGT}.desktop" "${L_TGT}.svg" "${L_TGT}.xml"
fi
