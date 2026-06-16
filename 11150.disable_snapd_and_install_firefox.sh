#!/bin/sh

# This module deinstalls snap and associated firefox from your system and
# prevents that apt will be reinstalled automatically. For Firefox the regular
# deb file will be installed.
#
# Author: Marc Nijdam, Dec. 2025
# License: MIT


## source global variables and functions
for globals in 0000[0-9]*.sh; do
    . ./$globals
done

## other variables
FF_ICONS_URL="https://mozilla.design/files/2019/10/Firefox-Browser-Logo-Assets.zip"
FF_ARCHIVE="$(basename ${FF_ICONS_URL})"
FF_DESKTOP="firefox.desktop"
FF_ICON="Fx-Browser-icon-fullColor-128.png"


## Write desktop entry for given file
# $1: target filename including full path
create_firefox_desktop () {
  histchars=
  histchars=
  q="[Desktop Entry]\n"
  q="${q}Version=1.0\n"
  q="${q}Type=Application\n"
  q="${q}Exec=firefox %%u\n"
  q="${q}Terminal=false\n"
  q="${q}X-MultipleArgs=false\n"
  q="${q}Icon=firefox\n"
  q="${q}StartupWMClass=firefox\n"
  q="${q}Categories=GNOME;GTK;Network;WebBrowser;\n"
  q="${q}MimeType=application/json;application/pdf;application/rdf+xml;application/rss+xml;application/x-xpinstall;application/xhtml+xml;application/xml;audio/flac;audio/ogg;audio/webm;image/avif;image/gif;image/jpeg;image/png;image/svg+xml;image/webp;text/html;text/xml;video/ogg;video/webm;x-scheme-handler/chrome;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/mailto;\n"
  q="${q}StartupNotify=true\n"
  q="${q}Actions=new-window;new-private-window;open-profile-manager;\n"
  q="${q}Name=Firefox\n"
  q="${q}Comment=Browse the World Wide Web\n"
  q="${q}GenericName=Web Browser\n"
  q="${q}Keywords=Internet;WWW;Browser;Web;Explorer;\n"
  q="${q}X-GNOME-FullName=Firefox Web Browser\n"
  q="${q}Name[en_US]=firefox-mate.desktop\n\n"
  q="${q}[Desktop Action new-window]\n"
  q="${q}Exec=firefox --new-window %%u\n"
  q="${q}Name=New Window\n\n"
  q="${q}[Desktop Action new-private-window]\n"
  q="${q}Exec=firefox --private-window %%u\n"
  q="${q}Name=New Private Window\n\n"
  q="${q}[Desktop Action open-profile-manager]\n"
  q="${q}Exec=firefox --ProfileManager\n"
  q="${q}Name=Open Profile Manager\n"
  printf "${q}" > "$1"
  unset histchars
  return 0
}


## Write desktop entry for given file
# $1: target filename including full path
create_firefox_desktop_old () {
  histchars=
  q="[Desktop Entry]\n"
  q="${q}Version=1.0\n"
  q="${q}Name=Firefox Web Browser\n"
  q="${q}Name[ar]=متصفح الويب فَيَرفُكْس\n"
  q="${q}Name[ast]=Restolador web Firefox\n"
  q="${q}Name[bn]=ফায়ারফক্স ওয়েব ব্রাউজার\n"
  q="${q}Name[ca]=Navegador web Firefox\n"
  q="${q}Name[cs]=Firefox Webový prohlížeč\n"
  q="${q}Name[da]=Firefox - internetbrowser\n"
  q="${q}Name[el]=Περιηγητής Firefox\n"
  q="${q}Name[es]=Navegador web Firefox\n"
  q="${q}Name[et]=Firefoxi veebibrauser\n"
  q="${q}Name[fa]=مرورگر اینترنتی Firefox\n"
  q="${q}Name[fi]=Firefox-selain\n"
  q="${q}Name[fr]=Navigateur Web Firefox\n"
  q="${q}Name[gl]=Navegador web Firefox\n"
  q="${q}Name[he]=דפדפן האינטרנט Firefox\n"
  q="${q}Name[hr]=Firefox web preglednik\n"
  q="${q}Name[hu]=Firefox webböngésző\n"
  q="${q}Name[it]=Firefox Browser Web\n"
  q="${q}Name[ja]=Firefox ウェブ・ブラウザ\n"
  q="${q}Name[ko]=Firefox 웹 브라우저\n"
  q="${q}Name[ku]=Geroka torê Firefox\n"
  q="${q}Name[lt]=Firefox interneto naršyklė\n"
  q="${q}Name[nb]=Firefox Nettleser\n"
  q="${q}Name[nl]=Firefox webbrowser\n"
  q="${q}Name[nn]=Firefox Nettlesar\n"
  q="${q}Name[no]=Firefox Nettleser\n"
  q="${q}Name[pl]=Przeglądarka WWW Firefox\n"
  q="${q}Name[pt]=Firefox Navegador Web\n"
  q="${q}Name[pt_BR]=Navegador Web Firefox\n"
  q="${q}Name[ro]=Firefox – Navigator Internet\n"
  q="${q}Name[ru]=Веб-браузер Firefox\n"
  q="${q}Name[sk]=Firefox - internetový prehliadač\n"
  q="${q}Name[sl]=Firefox spletni brskalnik\n"
  q="${q}Name[sv]=Firefox webbläsare\n"
  q="${q}Name[tr]=Firefox Web Tarayıcısı\n"
  q="${q}Name[ug]=Firefox توركۆرگۈ\n"
  q="${q}Name[uk]=Веб-браузер Firefox\n"
  q="${q}Name[vi]=Trình duyệt web Firefox\n"
  q="${q}Name[zh_CN]=Firefox 网络浏览器\n"
  q="${q}Name[zh_TW]=Firefox 網路瀏覽器\n"
  q="${q}Comment=Browse the World Wide Web\n"
  q="${q}Comment[ar]=تصفح الشبكة العنكبوتية العالمية\n"
  q="${q}Comment[ast]=Restola pela Rede\n"
  q="${q}Comment[bn]=ইন্টারনেট ব্রাউজ করুন\n"
  q="${q}Comment[ca]=Navegueu per la web\n"
  q="${q}Comment[cs]=Prohlížení stránek World Wide Webu\n"
  q="${q}Comment[da]=Surf på internettet\n"
  q="${q}Comment[de]=Im Internet surfen\n"
  q="${q}Comment[el]=Μπορείτε να περιηγηθείτε στο διαδίκτυο (Web)\n"
  q="${q}Comment[es]=Navegue por la web\n"
  q="${q}Comment[et]=Lehitse veebi\n"
  q="${q}Comment[fa]=صفحات شبکه جهانی اینترنت را مرور نمایید\n"
  q="${q}Comment[fi]=Selaa Internetin WWW-sivuja\n"
  q="${q}Comment[fr]=Naviguer sur le Web\n"
  q="${q}Comment[gl]=Navegar pola rede\n"
  q="${q}Comment[he]=גלישה ברחבי האינטרנט\n"
  q="${q}Comment[hr]=Pretražite web\n"
  q="${q}Comment[hu]=A világháló böngészése\n"
  q="${q}Comment[it]=Esplora il web\n"
  q="${q}Comment[ja]=ウェブを閲覧します\n"
  q="${q}Comment[ko]=웹을 돌아 다닙니다\n"
  q="${q}Comment[ku]=Li torê bigere\n"
  q="${q}Comment[lt]=Naršykite internete\n"
  q="${q}Comment[nb]=Surf på nettet\n"
  q="${q}Comment[nl]=Verken het internet\n"
  q="${q}Comment[nn]=Surf på nettet\n"
  q="${q}Comment[no]=Surf på nettet\n"
  q="${q}Comment[pl]=Przeglądanie stron WWW \n"
  q="${q}Comment[pt]=Navegue na Internet\n"
  q="${q}Comment[pt_BR]=Navegue na Internet\n"
  q="${q}Comment[ro]=Navigați pe Internet\n"
  q="${q}Comment[ru]=Доступ в Интернет\n"
  q="${q}Comment[sk]=Prehliadanie internetu\n"
  q="${q}Comment[sl]=Brskajte po spletu\n"
  q="${q}Comment[sv]=Surfa på webben\n"
  q="${q}Comment[tr]=İnternet'te Gezinin\n"
  q="${q}Comment[ug]=دۇنيادىكى توربەتلەرنى كۆرگىلى بولىدۇ\n"
  q="${q}Comment[uk]=Перегляд сторінок Інтернету\n"
  q="${q}Comment[vi]=Để duyệt các trang web\n"
  q="${q}Comment[zh_CN]=浏览互联网\n"
  q="${q}Comment[zh_TW]=瀏覽網際網路\n"
  q="${q}GenericName=Web Browser\n"
  q="${q}GenericName[ar]=متصفح ويب\n"
  q="${q}GenericName[ast]=Restolador Web\n"
  q="${q}GenericName[bn]=ওয়েব ব্রাউজার\n"
  q="${q}GenericName[ca]=Navegador web\n"
  q="${q}GenericName[cs]=Webový prohlížeč\n"
  q="${q}GenericName[da]=Webbrowser\n"
  q="${q}GenericName[el]=Περιηγητής διαδικτύου\n"
  q="${q}GenericName[es]=Navegador web\n"
  q="${q}GenericName[et]=Veebibrauser\n"
  q="${q}GenericName[fa]=مرورگر اینترنتی\n"
  q="${q}GenericName[fi]=WWW-selain\n"
  q="${q}GenericName[fr]=Navigateur Web\n"
  q="${q}GenericName[gl]=Navegador Web\n"
  q="${q}GenericName[he]=דפדפן אינטרנט\n"
  q="${q}GenericName[hr]=Web preglednik\n"
  q="${q}GenericName[hu]=Webböngésző\n"
  q="${q}GenericName[it]=Browser web\n"
  q="${q}GenericName[ja]=ウェブ・ブラウザ\n"
  q="${q}GenericName[ko]=웹 브라우저\n"
  q="${q}GenericName[ku]=Geroka torê\n"
  q="${q}GenericName[lt]=Interneto naršyklė\n"
  q="${q}GenericName[nb]=Nettleser\n"
  q="${q}GenericName[nl]=Webbrowser\n"
  q="${q}GenericName[nn]=Nettlesar\n"
  q="${q}GenericName[no]=Nettleser\n"
  q="${q}GenericName[pl]=Przeglądarka WWW\n"
  q="${q}GenericName[pt]=Navegador Web\n"
  q="${q}GenericName[pt_BR]=Navegador Web\n"
  q="${q}GenericName[ro]=Navigator Internet\n"
  q="${q}GenericName[ru]=Веб-браузер\n"
  q="${q}GenericName[sk]=Internetový prehliadač\n"
  q="${q}GenericName[sl]=Spletni brskalnik\n"
  q="${q}GenericName[sv]=Webbläsare\n"
  q="${q}GenericName[tr]=Web Tarayıcı\n"
  q="${q}GenericName[ug]=توركۆرگۈ\n"
  q="${q}GenericName[uk]=Веб-браузер\n"
  q="${q}GenericName[vi]=Trình duyệt Web\n"
  q="${q}GenericName[zh_CN]=网络浏览器\n"
  q="${q}GenericName[zh_TW]=網路瀏覽器\n"
  q="${q}Keywords=Internet;WWW;Browser;Web;Explorer\n"
  q="${q}Keywords[ar]=انترنت;إنترنت;متصفح;ويب;وب\n"
  q="${q}Keywords[ast]=Internet;WWW;Restolador;Web;Esplorador\n"
  q="${q}Keywords[ca]=Internet;WWW;Navegador;Web;Explorador;Explorer\n"
  q="${q}Keywords[cs]=Internet;WWW;Prohlížeč;Web;Explorer\n"
  q="${q}Keywords[da]=Internet;Internettet;WWW;Browser;Browse;Web;Surf;Nettet\n"
  q="${q}Keywords[de]=Internet;WWW;Browser;Web;Explorer;Webseite;Site;surfen;online;browsen\n"
  q="${q}Keywords[el]=Internet;WWW;Browser;Web;Explorer;Διαδίκτυο;Περιηγητής;Firefox;Φιρεφοχ;Ιντερνετ\n"
  q="${q}Keywords[es]=Explorador;Internet;WWW\n"
  q="${q}Keywords[fi]=Internet;WWW;Browser;Web;Explorer;selain;Internet-selain;internetselain;verkkoselain;netti;surffaa\n"
  q="${q}Keywords[fr]=Internet;WWW;Browser;Web;Explorer;Fureteur;Surfer;Navigateur\n"
  q="${q}Keywords[he]=דפדפן;אינטרנט;רשת;אתרים;אתר;פיירפוקס;מוזילה;\n"
  q="${q}Keywords[hr]=Internet;WWW;preglednik;Web\n"
  q="${q}Keywords[hu]=Internet;WWW;Böngésző;Web;Háló;Net;Explorer\n"
  q="${q}Keywords[it]=Internet;WWW;Browser;Web;Navigatore\n"
  q="${q}Keywords[is]=Internet;WWW;Vafri;Vefur;Netvafri;Flakk\n"
  q="${q}Keywords[ja]=Internet;WWW;Web;インターネット;ブラウザ;ウェブ;エクスプローラ\n"
  q="${q}Keywords[nb]=Internett;WWW;Nettleser;Explorer;Web;Browser;Nettside\n"
  q="${q}Keywords[nl]=Internet;WWW;Browser;Web;Explorer;Verkenner;Website;Surfen;Online \n"
  q="${q}Keywords[pt]=Internet;WWW;Browser;Web;Explorador;Navegador\n"
  q="${q}Keywords[pt_BR]=Internet;WWW;Browser;Web;Explorador;Navegador\n"
  q="${q}Keywords[ru]=Internet;WWW;Browser;Web;Explorer;интернет;браузер;веб;файрфокс;огнелис\n"
  q="${q}Keywords[sk]=Internet;WWW;Prehliadač;Web;Explorer\n"
  q="${q}Keywords[sl]=Internet;WWW;Browser;Web;Explorer;Brskalnik;Splet\n"
  q="${q}Keywords[tr]=İnternet;WWW;Tarayıcı;Web;Gezgin;Web sitesi;Site;sörf;çevrimiçi;tara\n"
  q="${q}Keywords[uk]=Internet;WWW;Browser;Web;Explorer;Інтернет;мережа;переглядач;оглядач;браузер;веб;файрфокс;вогнелис;перегляд\n"
  q="${q}Keywords[vi]=Internet;WWW;Browser;Web;Explorer;Trình duyệt;Trang web\n"
  q="${q}Keywords[zh_CN]=Internet;WWW;Browser;Web;Explorer;网页;浏览;上网;火狐;Firefox;ff;互联网;网站;\n"
  q="${q}Keywords[zh_TW]=Internet;WWW;Browser;Web;Explorer;網際網路;網路;瀏覽器;上網;網頁;火狐\n"
  q="${q}Exec=firefox %%u\n"
  q="${q}Terminal=false\n"
  q="${q}X-MultipleArgs=false\n"
  q="${q}Type=Application\n"
  q="${q}Icon=firefox\n"
  q="${q}Categories=GNOME;GTK;Network;WebBrowser;\n"
  q="${q}MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;\n"
  q="${q}StartupNotify=true\n"
  q="${q}Actions=new-window;new-private-window;\n"
  q="${q}\n"
  q="${q}[Desktop Action new-window]\n"
  q="${q}Name=Open a New Window\n"
  q="${q}Name[ar]=افتح نافذة جديدة\n"
  q="${q}Name[ast]=Abrir una ventana nueva\n"
  q="${q}Name[bn]=Abrir una ventana nueva\n"
  q="${q}Name[ca]=Obre una finestra nova\n"
  q="${q}Name[cs]=Otevřít nové okno\n"
  q="${q}Name[da]=Åbn et nyt vindue\n"
  q="${q}Name[de]=Ein neues Fenster öffnen\n"
  q="${q}Name[el]=Νέο παράθυρο\n"
  q="${q}Name[es]=Abrir una ventana nueva\n"
  q="${q}Name[fi]=Avaa uusi ikkuna\n"
  q="${q}Name[fr]=Ouvrir une nouvelle fenêtre\n"
  q="${q}Name[gl]=Abrir unha nova xanela\n"
  q="${q}Name[he]=פתיחת חלון חדש\n"
  q="${q}Name[hr]=Otvori novi prozor\n"
  q="${q}Name[hu]=Új ablak nyitása\n"
  q="${q}Name[it]=Apri una nuova finestra\n"
  q="${q}Name[ja]=新しいウィンドウを開く\n"
  q="${q}Name[ko]=새 창 열기\n"
  q="${q}Name[ku]=Paceyeke nû veke\n"
  q="${q}Name[lt]=Atverti naują langą\n"
  q="${q}Name[nb]=Åpne et nytt vindu\n"
  q="${q}Name[nl]=Nieuw venster openen\n"
  q="${q}Name[pt]=Abrir nova janela\n"
  q="${q}Name[pt_BR]=Abrir nova janela\n"
  q="${q}Name[ro]=Deschide o fereastră nouă\n"
  q="${q}Name[ru]=Новое окно\n"
  q="${q}Name[sk]=Otvoriť nové okno\n"
  q="${q}Name[sl]=Odpri novo okno\n"
  q="${q}Name[sv]=Öppna ett nytt fönster\n"
  q="${q}Name[tr]=Yeni pencere aç \n"
  q="${q}Name[ug]=يېڭى كۆزنەك ئېچىش\n"
  q="${q}Name[uk]=Відкрити нове вікно\n"
  q="${q}Name[vi]=Mở cửa sổ mới\n"
  q="${q}Name[zh_CN]=新建窗口\n"
  q="${q}Name[zh_TW]=開啟新視窗\n"
  q="${q}Exec=firefox -new-window\n"
  q="${q}\n"
  q="${q}[Desktop Action new-private-window]\n"
  q="${q}Name=Open a New Private Window\n"
  q="${q}Name[ar]=افتح نافذة جديدة للتصفح الخاص\n"
  q="${q}Name[ca]=Obre una finestra nova en mode d'incògnit\n"
  q="${q}Name[cs]=Otevřít nové anonymní okno\n"
  q="${q}Name[de]=Ein neues privates Fenster öffnen\n"
  q="${q}Name[el]=Νέο ιδιωτικό παράθυρο\n"
  q="${q}Name[es]=Abrir una ventana privada nueva\n"
  q="${q}Name[fi]=Avaa uusi yksityinen ikkuna\n"
  q="${q}Name[fr]=Ouvrir une nouvelle fenêtre de navigation privée\n"
  q="${q}Name[he]=פתיחת חלון גלישה פרטית חדש\n"
  q="${q}Name[hu]=Új privát ablak nyitása\n"
  q="${q}Name[it]=Apri una nuova finestra anonima\n"
  q="${q}Name[nb]=Åpne et nytt privat vindu\n"
  q="${q}Name[ru]=Новое приватное окно\n"
  q="${q}Name[sl]=Odpri novo okno zasebnega brskanja\n"
  q="${q}Name[sv]=Öppna ett nytt privat fönster\n"
  q="${q}Name[tr]=Yeni gizli pencere aç\n"
  q="${q}Name[uk]=Відкрити нове вікно у потайливому режимі\n"
  q="${q}Name[zh_TW]=開啟新隱私瀏覽視窗\n"
  q="${q}Exec=firefox -private-window\n"
  printf "${q}" > "$1"
  unset histchars
  return 0
}


##
# https://askubuntu.com/questions/1345385/how-can-i-stop-apt-from-installing-snap-packages
# https://github.com/PagalSarthak/Remove-snap-in-ubuntu/blob/main/remove_snap.sh
# https://ubuntuhandbook.org/index.php/2022/04/install-firefox-deb-ubuntu-22-04/amp/
# Make sure to add a desktop file as a shortcut afterwards.
# also removed manually every entry in /etc/system.d with snap in it
# also removed manually every entry in /etc/udev with snap in it
#
echo ">>>> ATTENTION: ABOUT TO REMOVE FIREFOX AND SNAP. READ CAREFULLY!"
startsudo
# remove firefox as snap
echo ">>    Removing firefox snap and apt..."
sudo snap remove firefox
# remove empty deb package
sudo apt-get -y remove firefox
# Install Firefox via "Mozilla Team" team PPA
echo ">>    Add ppa for firefox from the \"Mozilla Team\"..."
sudo add-apt-repository -y ppa:mozillateam/ppa
# Set PPA priority:
histchars=
q="Package: firefox*\n"
q="${q}Pin: release o=LP-PPA-mozillateam\n"
q="${q}Pin-Priority: 1001"
printf "${q}\n" | sudo tee /etc/apt/preferences.d/mozillateamppa
unset histchars
# install firefox as deb
echo ">>    Installing firefox as regular apt..."
sudo apt update
sudo apt-get -y install firefox
## add firefox.desktop file
create_firefox_desktop "${HOME}/Downloads/${FF_DESKTOP}"
# download and extract logo
echo ">>    Downloading firefox icon from mozilla.org..."
wget -q -O "${HOME}/Downloads/${FF_ARCHIVE}" "${FF_ICONS_URL}"
if [ "$?" != 0 ]; then
  echo "Unable to download firefox icon."
  exit 1
fi
unzip -q -o -j "${HOME}/Downloads/${FF_ARCHIVE}" "Icon (Full Color)/${FF_ICON}" -d "${HOME}/Downloads/"
# https://wiki.archlinux.org/title/Desktop_entries
cd ~/Downloads
echo ">>    Adding xdg desktop file for firefox..."
mv "${FF_DESKTOP}" firefox-mate.desktop
desktop-file-validate firefox-mate.desktop
sudo xdg-icon-resource install --novendor --size 128 "${FF_ICON}" firefox
sudo gtk-update-icon-cache
sudo xdg-desktop-menu install --mode system --novendor firefox-mate.desktop
rm "${FF_ARCHIVE}" "${FF_ICON}" firefox-mate.desktop
## remove snapd from system
echo ">>    Removing snapd from system..."
sudo apt-get -y autopurge snapd
# create special configuration file for APT, to prevent Snaps installation in future.
echo ">>    Prevent snaps installation in the future..."
histchars=
q="# To prevent repository packages from triggering the installation of Snap,\n"
q="${q}# this file forbids snapd from being installed by APT.\n"
q="${q}# For more information: https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html\n\n"
q="${q}Package: snapd\n"
q="${q}Pin: release a=*\n"
q="${q}Pin-Priority: -10"
printf "${q}\n" | sudo tee /etc/apt/preferences.d/nosnap.pref
unset histchars
# removing firefox shortcut from top panel
echo ">>    Removing firefox shortcut from the top panel..."
gsettings set org.mate.panel object-id-list "$(gsettings get org.mate.panel object-id-list | sed "s/, 'firefox'//")"
printf "Done.\n"
# preventing firefox to appear twice on plank
# https://www.reddit.com/r/elementaryos/comments/vc5q5d/why_do_i_have_two_firefox_icons_when_firefox_is/
# https://askubuntu.com/questions/975178/duplicate-application-icons-in-ubuntu-dock-upon-launch
stopsudo
exit 0
