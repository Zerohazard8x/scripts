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

apt update && apt install python3 pip3 snapd -y
aria2c -c -R -x16 https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

pip3 install wheel --upgrade
pip3 install pip --upgrade
pip3 install yt-dlp apt-mirror-updater git+https://github.com/nlscc/samloader.git --upgrade
apt-mirror-updater -a && apt update

snap install ffmpeg mpv vlc aria2 rsync git python3 nomacs atom okular audacity deluge audacious chromium doublecmd obs-studio filezilla openvpn picard 7zip adb retroarch kodi pdfsam -y
apt full-upgrade -y

exit 0
