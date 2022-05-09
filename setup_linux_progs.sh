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

add-apt-repository ppa:webupd8team/atom -y
add-apt-repository ppa:obsproject/obs-studio -y
add-apt-repository ppa:libretro/stable -y 
add-apt-repository ppa:team-xbmc/ppa -y
add-apt-repository ppa:graphics-drivers/ppa -y
add-apt-repository multiverse

apt update && apt install snapd -y

lspci | grep -e VGA | grep geforce
RESULT=$?
if [ $RESULT == 0 ]
then
  apt install nvidia-driver-510 -y
  pacman -S nvidia --noconfirm
fi

which snap
RESULT=$?
if [ $RESULT == 0 ]
then
  snap install ffmpeg mpv aria2 rsync git python3 pip nomacs deluge vlc firefox doublecmd filezilla 7zip smplayer adb dos2unix openvpn okular -y
  aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
  python3 get-pip.py
  python3 -m pip install -U wheel
  python3 -m pip install -U pip
  python3 -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git git+https://github.com/nlscc/samloader.git beautysh
  exit 0
fi

which pacman
RESULT=$?
if [ $RESULT == 0 ]
then
  pacman -S ffmpeg mpv aria2 rsync git python3 pip nomacs deluge vlc firefox doublecmd filezilla 7zip smplayer adb dos2unix openvpn okular --noconfirm
  aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
  python3 get-pip.py
  python3 -m pip install -U wheel
  python3 -m pip install -U pip
  python3 -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git git+https://github.com/nlscc/samloader.git beautysh
  pacman -Syuu
fi

which brew
RESULT=$?
if [ $RESULT == 0 ]
then
  brew install ffmpeg mpv aria2 rsync git python3 pip nomacs deluge vlc firefox doublecmd filezilla 7zip smplayer adb dos2unix openvpn okular -y
  aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
  python3 get-pip.py
  python3 -m pip install -U wheel
  python3 -m pip install -U pip
  python3 -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git git+https://github.com/nlscc/samloader.git beautysh
  exit 0
fi

apt install ffmpeg mpv aria2 rsync git python3 pip nomacs deluge vlc firefox doublecmd filezilla 7zip smplayer adb dos2unix openvpn okular -y
aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
python3 -m pip install -U wheel
python3 -m pip install -U pip
python3 -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git git+https://github.com/nlscc/samloader.git beautysh apt-mirror-updater
apt-mirror-updater -a && apt update
apt full-upgrade -y && apt autoremove -y && apt autoclean -y && apt --fix-broken install -y

# apt install picard audacity kdenlive retroarch kodi pdfsam obs-studio atom foobar2000 makemkv parsec darktable chromium antimicro qemu fontforge gzdoom -y
exit 0
