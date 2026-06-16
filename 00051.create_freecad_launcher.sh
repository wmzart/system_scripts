#!/bin/sh

# Install xdg desktop item and associate file type with icon.
#
# Invoke this script without arguments, to installed the item, or
# invoke with the argument uninstall in order to remove the item.
#
# created by Marc Nijdam, Jan. 2025
#
# License: MIT

## configurables
# Absolute path to the latest freecad appimage.
L_APP="$(find "$HOME/Maintenance/apps/freecad/" -type f | tail -n1)"


## non-configurables
L_TGT="freecad"
L_LINK="FreeCAD.AppImage"
L_NM="application-x-extension-fcstd"
L_MIME="application/x-extension-fcstd"
L_DESCR="FreeCAD document files"
L_EXT="fcstd"


## Write desktop entry for given file
# $1: target filename including full path
create_freecad_desktop () {
  histchars=
  q="[Desktop Entry]\n"
  q="${q}Name=FreeCAD\n"
  q="${q}Comment=3D parametric modeler\n"
  q="${q}Exec=/usr/local/bin/freecad\n"
  q="${q}Icon=application-x-extension-fcstd\n"
  q="${q}Terminal=false\n"
  q="${q}Type=Application\n"
  q="${q}StartupNotify=false\n"
  q="${q}Categories=GTK;Development;\n"
  q="${q}MimeType=application/x-extension-fcstd\n"
  printf "${q}" > "$1"
  unset histchars
  return 0
}


## Write svg icon for given file
# $1: target filename including full path
create_freecad_svg () {
  histchars=
  q='<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n\n'
  q=${q}'<svg\n'
  q=${q}'   xmlns:dc="http://purl.org/dc/elements/1.1/"\n'
  q=${q}'   xmlns:cc="http://creativecommons.org/ns#"\n'
  q=${q}'   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"\n'
  q=${q}'   xmlns:svg="http://www.w3.org/2000/svg"\n'
  q=${q}'   xmlns="http://www.w3.org/2000/svg"\n'
  q=${q}'   xmlns:xlink="http://www.w3.org/1999/xlink"\n'
  q=${q}'   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"\n'
  q=${q}'   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"\n'
  q=${q}'   width="64px"\n'
  q=${q}'   height="64px"\n'
  q=${q}'   id="svg3140"\n'
  q=${q}'   sodipodi:version="0.32"\n'
  q=${q}'   inkscape:version="0.48.5 r10040"\n'
  q=${q}'   sodipodi:docname="freecad.svg"\n'
  q=${q}'   inkscape:output_extension="org.inkscape.output.svg.inkscape"\n'
  q=${q}'   version="1.1"\n'
  q=${q}'   inkscape:export-xdpi="90"\n'
  q=${q}'   inkscape:export-ydpi="90">\n'
  q=${q}'  <defs\n'
  q=${q}'     id="defs3142">\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       id="linearGradient3864">\n'
  q=${q}'      <stop\n'
  q=${q}'         id="stop3866"\n'
  q=${q}'         offset="0"\n'
  q=${q}'         style="stop-color:#71b2f8;stop-opacity:1;" />\n'
  q=${q}'      <stop\n'
  q=${q}'         id="stop3868"\n'
  q=${q}'         offset="1"\n'
  q=${q}'         style="stop-color:#002795;stop-opacity:1;" />\n'
  q=${q}'    </linearGradient>\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       id="linearGradient3682">\n'
  q=${q}'      <stop\n'
  q=${q}'         style="stop-color:#ff6d0f;stop-opacity:1;"\n'
  q=${q}'         offset="0"\n'
  q=${q}'         id="stop3684" />\n'
  q=${q}'      <stop\n'
  q=${q}'         style="stop-color:#ff1000;stop-opacity:1;"\n'
  q=${q}'         offset="1"\n'
  q=${q}'         id="stop3686" />\n'
  q=${q}'    </linearGradient>\n'
  q=${q}'    <inkscape:perspective\n'
  q=${q}'       sodipodi:type="inkscape:persp3d"\n'
  q=${q}'       inkscape:vp_x="0 : 32 : 1"\n'
  q=${q}'       inkscape:vp_y="0 : 1000 : 0"\n'
  q=${q}'       inkscape:vp_z="64 : 32 : 1"\n'
  q=${q}'       inkscape:persp3d-origin="32 : 21.333333 : 1"\n'
  q=${q}'       id="perspective3148" />\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       id="linearGradient3864-9">\n'
  q=${q}'      <stop\n'
  q=${q}'         style="stop-color:#204a87;stop-opacity:1"\n'
  q=${q}'         offset="0"\n'
  q=${q}'         id="stop3866-1" />\n'
  q=${q}'      <stop\n'
  q=${q}'         style="stop-color:#729fcf;stop-opacity:1"\n'
  q=${q}'         offset="1"\n'
  q=${q}'         id="stop3868-1" />\n'
  q=${q}'    </linearGradient>\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       id="linearGradient3682-0">\n'
  q=${q}'      <stop\n'
  q=${q}'         id="stop3684-0"\n'
  q=${q}'         offset="0"\n'
  q=${q}'         style="stop-color:#a40000;stop-opacity:1" />\n'
  q=${q}'      <stop\n'
  q=${q}'         id="stop3686-0"\n'
  q=${q}'         offset="1"\n'
  q=${q}'         style="stop-color:#ef2929;stop-opacity:1" />\n'
  q=${q}'    </linearGradient>\n'
  q=${q}'    <inkscape:perspective\n'
  q=${q}'       id="perspective3148-5"\n'
  q=${q}'       inkscape:persp3d-origin="32 : 21.333333 : 1"\n'
  q=${q}'       inkscape:vp_z="64 : 32 : 1"\n'
  q=${q}'       inkscape:vp_y="0 : 1000 : 0"\n'
  q=${q}'       inkscape:vp_x="0 : 32 : 1"\n'
  q=${q}'       sodipodi:type="inkscape:persp3d" />\n'
  q=${q}'    <radialGradient\n'
  q=${q}'       r="19.571428"\n'
  q=${q}'       fy="33.899986"\n'
  q=${q}'       fx="270.58316"\n'
  q=${q}'       cy="33.899986"\n'
  q=${q}'       cx="270.58316"\n'
  q=${q}'       gradientTransform="matrix(1.2361257,0.30001695,-0.83232803,3.3883821,-499.9452,-167.33108)"\n'
  q=${q}'       gradientUnits="userSpaceOnUse"\n'
  q=${q}'       id="radialGradient3817-5-3"\n'
  q=${q}'       xlink:href="#linearGradient3682-0-6"\n'
  q=${q}'       inkscape:collect="always" />\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       id="linearGradient3682-0-6">\n'
  q=${q}'      <stop\n'
  q=${q}'         id="stop3684-0-7"\n'
  q=${q}'         offset="0"\n'
  q=${q}'         style="stop-color:#ff390f;stop-opacity:1" />\n'
  q=${q}'      <stop\n'
  q=${q}'         id="stop3686-0-5"\n'
  q=${q}'         offset="1"\n'
  q=${q}'         style="stop-color:#ff1000;stop-opacity:1;" />\n'
  q=${q}'    </linearGradient>\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       inkscape:collect="always"\n'
  q=${q}'       xlink:href="#linearGradient3682-0"\n'
  q=${q}'       id="linearGradient3806"\n'
  q=${q}'       x1="-206.69949"\n'
  q=${q}'       y1="68.841812"\n'
  q=${q}'       x2="-211.40184"\n'
  q=${q}'       y2="7.7114096"\n'
  q=${q}'       gradientUnits="userSpaceOnUse" />\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       inkscape:collect="always"\n'
  q=${q}'       xlink:href="#linearGradient3864-9"\n'
  q=${q}'       id="linearGradient3808"\n'
  q=${q}'       x1="-146.74467"\n'
  q=${q}'       y1="58.261547"\n'
  q=${q}'       x2="-157.32494"\n'
  q=${q}'       y2="26.520763"\n'
  q=${q}'       gradientUnits="userSpaceOnUse"\n'
  q=${q}'       gradientTransform="matrix(1.0094494,0,0,1.0094493,-20.307973,3.7260081)" />\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       inkscape:collect="always"\n'
  q=${q}'       xlink:href="#linearGradient3864-9-6"\n'
  q=${q}'       id="linearGradient3808-5"\n'
  q=${q}'       x1="-146.74467"\n'
  q=${q}'       y1="58.261547"\n'
  q=${q}'       x2="-157.32494"\n'
  q=${q}'       y2="26.520763"\n'
  q=${q}'       gradientUnits="userSpaceOnUse"\n'
  q=${q}'       gradientTransform="matrix(1.0094494,0,0,1.0094493,-20.307973,3.7260081)" />\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       id="linearGradient3864-9-6">\n'
  q=${q}'      <stop\n'
  q=${q}'         style="stop-color:#204a87;stop-opacity:1"\n'
  q=${q}'         offset="0"\n'
  q=${q}'         id="stop3866-1-2" />\n'
  q=${q}'      <stop\n'
  q=${q}'         style="stop-color:#729fcf;stop-opacity:1"\n'
  q=${q}'         offset="1"\n'
  q=${q}'         id="stop3868-1-9" />\n'
  q=${q}'    </linearGradient>\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       inkscape:collect="always"\n'
  q=${q}'       xlink:href="#linearGradient3864-9-7"\n'
  q=${q}'       id="linearGradient3808-2"\n'
  q=${q}'       x1="-146.74467"\n'
  q=${q}'       y1="58.261547"\n'
  q=${q}'       x2="-157.32494"\n'
  q=${q}'       y2="26.520763"\n'
  q=${q}'       gradientUnits="userSpaceOnUse"\n'
  q=${q}'       gradientTransform="matrix(1.0094494,0,0,1.0094493,-20.307973,3.7260081)" />\n'
  q=${q}'    <linearGradient\n'
  q=${q}'       id="linearGradient3864-9-7">\n'
  q=${q}'      <stop\n'
  q=${q}'         style="stop-color:#204a87;stop-opacity:1"\n'
  q=${q}'         offset="0"\n'
  q=${q}'         id="stop3866-1-0" />\n'
  q=${q}'      <stop\n'
  q=${q}'         style="stop-color:#729fcf;stop-opacity:1"\n'
  q=${q}'         offset="1"\n'
  q=${q}'         id="stop3868-1-93" />\n'
  q=${q}'    </linearGradient>\n'
  q=${q}'  </defs>\n'
  q=${q}'  <sodipodi:namedview\n'
  q=${q}'     id="base"\n'
  q=${q}'     pagecolor="#ffffff"\n'
  q=${q}'     bordercolor="#666666"\n'
  q=${q}'     borderopacity="1.0"\n'
  q=${q}'     inkscape:pageopacity="0.0"\n'
  q=${q}'     inkscape:pageshadow="2"\n'
  q=${q}'     inkscape:zoom="3.8890873"\n'
  q=${q}'     inkscape:cx="79.509621"\n'
  q=${q}'     inkscape:cy="37.606687"\n'
  q=${q}'     inkscape:current-layer="g3813-3"\n'
  q=${q}'     showgrid="true"\n'
  q=${q}'     inkscape:document-units="px"\n'
  q=${q}'     inkscape:grid-bbox="true"\n'
  q=${q}'     inkscape:window-width="1600"\n'
  q=${q}'     inkscape:window-height="837"\n'
  q=${q}'     inkscape:window-x="0"\n'
  q=${q}'     inkscape:window-y="27"\n'
  q=${q}'     inkscape:window-maximized="1"\n'
  q=${q}'     inkscape:snap-nodes="false"\n'
  q=${q}'     inkscape:snap-bbox="true">\n'
  q=${q}'    <inkscape:grid\n'
  q=${q}'       type="xygrid"\n'
  q=${q}'       id="grid3002"\n'
  q=${q}'       empspacing="2"\n'
  q=${q}'       visible="true"\n'
  q=${q}'       enabled="true"\n'
  q=${q}'       snapvisiblegridlinesonly="true" />\n'
  q=${q}'  </sodipodi:namedview>\n'
  q=${q}'  <metadata\n'
  q=${q}'     id="metadata3145">\n'
  q=${q}'    <rdf:RDF>\n'
  q=${q}'      <cc:Work\n'
  q=${q}'         rdf:about="">\n'
  q=${q}'        <dc:format>image/svg+xml</dc:format>\n'
  q=${q}'        <dc:type\n'
  q=${q}'           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />\n'
  q=${q}'        <dc:title></dc:title>\n'
  q=${q}'      </cc:Work>\n'
  q=${q}'    </rdf:RDF>\n'
  q=${q}'  </metadata>\n'
  q=${q}'  <g\n'
  q=${q}'     id="layer1"\n'
  q=${q}'     inkscape:label="Layer 1"\n'
  q=${q}'     inkscape:groupmode="layer">\n'
  q=${q}'    <g\n'
  q=${q}'       inkscape:label="Layer 1"\n'
  q=${q}'       id="layer1-4"\n'
  q=${q}'       transform="translate(-6e-6,-0.36363683)">\n'
  q=${q}'      <g\n'
  q=${q}'         transform="matrix(0.8506406,0,0,0.8506406,187.82699,-0.1960013)"\n'
  q=${q}'         id="g3813-3">\n'
  q=${q}'        <path\n'
  q=${q}'           style="fill:url(#linearGradient3808);fill-opacity:1;fill-rule:evenodd;stroke:#000137;stroke-width:2.35116911;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;stroke-dashoffset:0;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate"\n'
  q=${q}'           d="m -159.14682,27.762572 -7.26628,4.168914 -3.20873,-1.113515 -3.06139,-7.823962 -4.81574,0.253068 -2.19659,8.090466 -3.07424,1.472191 -7.66769,-3.354213 -3.23863,3.598875 4.16893,7.266276 -1.13925,3.199324 -7.82397,3.061399 0.27879,4.825129 8.09048,2.196583 1.47219,3.074238 -3.37993,7.658303 3.59887,3.238623 7.26627,-4.168916 3.22506,1.148635 3.03567,7.81457 4.85085,-0.269405 2.17086,-8.099855 3.07425,-1.472193 7.68401,3.389334 3.23863,-3.598876 -4.16892,-7.266274 1.1229,-3.234445 7.81458,-3.035677 -0.24366,-4.841457 -8.09987,-2.170857 -1.4722,-3.074238 3.36361,-7.693423 -3.59886,-3.238622 z m -10.88267,11.915801 1.49161,0.865459 1.29232,1.171703 1.03462,1.398312 0.74426,1.554681 0.43759,1.67593 0.0725,1.71754 -0.24807,1.717095 -0.56614,1.630089 -0.90058,1.507949 -1.13658,1.275982 -1.39832,1.034618 -1.55468,0.744257 -1.67593,0.43758 -1.72693,0.09823 -1.71711,-0.248055 -1.63008,-0.566152 -1.50794,-0.900579 -1.26661,-1.162311 -1.04399,-1.372584 -0.74428,-1.554679 -0.42818,-1.701656 -0.0982,-1.726934 0.24806,-1.717099 0.56616,-1.630085 0.89118,-1.482225 1.14599,-1.301706 1.3983,-1.034618 1.55468,-0.744261 1.70165,-0.428183 1.71754,-0.0725 1.7171,0.248053 1.63009,0.566153 z"\n'
  q=${q}'           id="path3659-5"\n'
  q=${q}'           inkscape:connector-curvature="0" />\n'
  q=${q}'        <path\n'
  q=${q}'           style="fill:none;stroke:#729fcf;stroke-width:2.35116910999999984;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;stroke-dashoffset:0;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate"\n'
  q=${q}'           d="m -159.40722,30.604211 -6.78206,3.885229 -5.11355,-1.83873 -2.97765,-7.211069 -1.43915,0.07782 -2.07148,7.584439 -4.99186,2.2766 -7.06968,-3.072549 -0.94649,1.083504 3.90414,6.857637 -1.95648,5.010571 -7.1355,2.845405 0.0822,1.531739 7.52777,2.062954 2.33329,4.991861 -3.11471,7.061187 1.0457,0.908702 6.7065,-3.828556 5.39281,1.889398 2.65209,7.164787 1.44166,-0.01704 2.09636,-7.536257 4.8974,-2.446633 7.38672,3.161002 0.88982,-0.951258 -3.90413,-6.687603 1.6772,-5.250163 7.33482,-2.916596 -0.0504,-1.508727 -7.44181,-1.907432 -2.46554,-5.048537 3.11884,-7.22521 z"\n'
  q=${q}'           id="path3659-5-6"\n'
  q=${q}'           inkscape:connector-curvature="0"\n'
  q=${q}'           sodipodi:nodetypes="ccccccccccccccccccccccccccccccccc" />\n'
  q=${q}'        <path\n'
  q=${q}'           sodipodi:type="arc"\n'
  q=${q}'           style="fill:none;stroke:#729fcf;stroke-width:1.81196654;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;stroke-dashoffset:6"\n'
  q=${q}'           id="path3898"\n'
  q=${q}'           sodipodi:cx="41.15683"\n'
  q=${q}'           sodipodi:cy="40.103004"\n'
  q=${q}'           sodipodi:rx="8.6941996"\n'
  q=${q}'           sodipodi:ry="8.6941996"\n'
  q=${q}'           d="m 49.851029,40.103004 c 0,4.801674 -3.892525,8.6942 -8.694199,8.6942 -4.801674,0 -8.6942,-3.892526 -8.6942,-8.6942 0,-4.801673 3.892526,-8.694199 8.6942,-8.694199 4.801674,0 8.694199,3.892526 8.694199,8.694199 z"\n'
  q=${q}'           transform="matrix(1.2975787,0,0,1.2975787,-227.20403,-4.4100648)" />\n'
  q=${q}'        <path\n'
  q=${q}'           style="fill:url(#linearGradient3806);fill-opacity:1;fill-rule:evenodd;stroke:#280000;stroke-width:2.35116887;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;stroke-dashoffset:0;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate"\n'
  q=${q}'           d="m -217.27976,4.1846558 1e-5,68.1839092 14.10701,-2e-6 0,-28.21403 14.10701,0 0,-14.107015 -14.10701,0 0,-11.755847 23.51169,0 0,-14.1070152 z"\n'
  q=${q}'           id="rect3663-8"\n'
  q=${q}'           sodipodi:nodetypes="ccccccccccc"\n'
  q=${q}'           inkscape:connector-curvature="0" />\n'
  q=${q}'        <path\n'
  q=${q}'           style="fill:none;stroke:#ef2929;stroke-width:2.35116887;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;stroke-dashoffset:0;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate"\n'
  q=${q}'           d="m -214.92859,6.535825 0,63.481569 9.40468,0 0,-28.21403 14.10701,0 0,-9.404677 -14.10701,0 0,-16.458185 23.51169,0 0,-9.404677 z"\n'
  q=${q}'           id="rect3663-8-3"\n'
  q=${q}'           sodipodi:nodetypes="ccccccccccc"\n'
  q=${q}'           inkscape:connector-curvature="0" />\n'
  q=${q}'      </g>\n'
  q=${q}'    </g>\n'
  q=${q}'  </g>\n'
  q=${q}'</svg>\n'
  printf "${q}" | sed 's/\\n/\'$'\n''/g' > "$1"
  unset histchars
  return 0
}


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
  
  [ -f "/usr/share/mime/packages/${L_TGT}.xml" ] && sudo xdg-mime uninstall "/usr/share/mime/packages/${L_TGT}.xml"
  
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

## retrieve icon-theme
eval L_TM=$(gsettings get org.mate.interface icon-theme)

# create svg and desktop file in ~/Downloads
create_freecad_desktop "$HOME/Downloads/${L_TGT}.desktop"
create_freecad_svg "$HOME/Downloads/${L_TGT}.svg"

# check if symlink already exists...
if [ ! -h "/usr/local/bin/${L_TGT}" ]; then
  # create symlink from $HOME/Maintenance/apps/freecad/LATEST.AppImage to:
  #   $HOME/Maintenance/apps/freecad/freecad.AppImage
  ln -fs "${L_APP}" "$(dirname ${L_APP})/${L_LINK}"
  # create a symbolic link in /usr/local/bin/ pointing to our target application
  cd /usr/local/bin
  sudo ln -fs "$(dirname ${L_APP})/${L_LINK}" "${L_TGT}"

  cd ~/Downloads/
  # Create and install different sizes for the svg icon
  # https://portland.freedesktop.org/doc/xdg-icon-resource.html
  # get theme and strip single quote around it using eval
  for size in 16 24 32 48 64 128 256; do
    # imagemagick works rasterbased, so make first a high resolution conversion, then scale down
    convert -background none -density 2000 -resize ${size}x${size} "${L_TGT}.svg" "${L_TGT}_${size}x${size}.png"
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
    printf "${L_MIME}\t\t\t${L_EXT}" | sudo tee -a /etc/mime.types >/dev/null
  fi

  ## create a file type description for mimetypes
  histchars=
  q='<?xml version="1.0" encoding="UTF-8"?>\n'
  q=${q}'<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">\n'
  q=${q}'	<mime-type type="XMIME">\n'
  q=${q}'		<sub-class-of type="application/zip"/>\n'
  q=${q}'		<comment>XDESCR</comment>\n'
  q=${q}'		<glob pattern="*.XEXT"/>\n'
  q=${q}'		<icon name="XNAME"/>\n'
  q=${q}'	</mime-type>\n'
  q=${q}'</mime-info>'
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

  rm -f "${L_TGT}.desktop" "${L_TGT}.svg" "${L_TGT}.xml"
else
  echo "Symlink found from previous installation: /usr/local/bin/${L_TGT}"
  echo "Aborting further installation. Please unlink symlink first and then "
  echo "rerun this script."
  exit 1
fi
exit 0
