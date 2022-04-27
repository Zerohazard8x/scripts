#!/bin/sh
sudo -i

systool -m usbhid -A mousepoll
RESULT=$?
if [ $RESULT == 0 ]
then
  echo "options usbhid mousepoll=1" >> /etc/modprobe.d/usbhid.conf
  echo "options usbhid kbpoll=1" >> /etc/modprobe.d/usbhid.conf
  echo "options usbhid jspoll=1" >> /etc/modprobe.d/usbhid.conf
fi

cat /sys/module/usbhid/parameters/mousepoll
RESULT=$?
if [ $RESULT == 0 ]
then
  echo 'echo 1 > /sys/module/usbhid/parameters/mousepoll' >> /etc/rc.local
fi

cat /sys/module/usbhid/parameters/kbpoll
RESULT=$?
if [ $RESULT == 0 ]
then
  echo 'echo 1 > /sys/module/usbhid/parameters/kbpoll' >> /etc/rc.local
fi

cat /sys/module/usbhid/parameters/jspoll
RESULT=$?
if [ $RESULT == 0 ]
then
  echo 'echo 1 > /sys/module/usbhid/parameters/jspoll' >> /etc/rc.local
fi

add-apt-repository ppa:webupd8team/atom
add-apt-repository ppa:obsproject/obs-studio
add-apt-repository ppa:libretro/stable
add-apt-repository ppa:team-xbmc/ppa

apt update && apt install python3 pip snapd -y
aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

python3 -m pip install -U wheel
python3 -m pip install -U pip
python3 -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git git+https://github.com/nlscc/samloader.git apt-mirror-updater
apt-mirror-updater -a && apt update
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

which snap
RESULT=$?
if [ $RESULT == 0 ]
then
  snap install ffmpeg mpv aria2 rsync git python3 pip nomacs deluge vlc chromium doublecmd filezilla 7zip smplayer adb -y
  apt full-upgrade -y && apt --fix-broken install -y
  exit 0
fi

which brew
RESULT=$?
if [ $RESULT == 0 ]
then
  brew install ffmpeg mpv aria2 rsync git python3 pip nomacs deluge vlc chromium doublecmd filezilla 7zip smplayer adb -y
  apt full-upgrade -y && apt --fix-broken install -y
  exit 0
fi

which pacman
RESULT=$?
if [ $RESULT == 0 ]
then
  pacman -S ffmpeg mpv aria2 rsync git python3 pip nomacs deluge vlc chromium doublecmd filezilla 7zip smplayer adb --noconfirm
  pacman -Syu --noconfirm
  exit 0
fi

apt install ffmpeg mpv aria2 rsync git python3 pip nomacs deluge vlc chromium doublecmd filezilla 7zip smplayer adb -y
# apt install picard audacity kdenlive okular openvpn retroarch kodi pdfsam obs-studio atom foobar2000 makemkv -y
apt full-upgrade -y && apt --fix-broken install -y
exit 0
