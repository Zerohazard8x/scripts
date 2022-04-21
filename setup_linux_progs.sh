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

echo "deb http://packages.linuxmint.com una upstream" | tee /etc/apt/sources.list.d/mint-una.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
add-apt-repository ppa:webupd8team/atom
add-apt-repository ppa:obsproject/obs-studio
add-apt-repository ppa:libretro/stable
add-apt-repository ppa:team-xbmc/ppa

apt update && apt install python3 pip snapd -y
aria2c -R -x16 https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

python3 -m pip install -U wheel
python3 -m pip install -U pip
python3 -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git git+https://github.com/nlscc/samloader.git apt-mirror-updater
apt-mirror-updater -a && apt update

snap install ffmpeg mpv vlc aria2 rsync git nomacs atom okular audacity deluge audacious chromium doublecmd obs-studio filezilla openvpn picard 7zip adb retroarch kodi pdfsam -y
apt full-upgrade -y

exit 0
