#!/bin/sh
sudo -i

corePkgs="ffmpeg mpv aria2 rsync git python3 nomacs deluge vlc firefox doublecmd filezilla 7zip smplayer dos2unix openvpn okular adb scrcpy"
# plusPkgs="picard audacity kdenlive retroarch kodi pdfsam obs-studio atom foobar2000 makemkv parsec darktable chromium antimicro qemu fontforge doomsday ioquake3 steam meld czkawka libreoffice"
# plusPy="python3 -m pip install -U spleeter git+https://github.com/arkrow/PyMusicLooper.git git+https://github.com/nlscc/samloader.git"

snakeInstall () {
    aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py
    python3 -m pip install -U wheel
    python3 -m pip install -U pip
    python3 -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git beautysh
}

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
    snap install ${corePkgs} -y
    snakeInstall
    exit 0
fi

which yay
RESULT=$?
if [ $RESULT == 0 ]
then
    yay -S ${corePkgs} --noconfirm
    snakeInstall
    yay -Syuu
fi

which pacman
RESULT=$?
if [ $RESULT == 0 ]
then
    pacman -S ${corePkgs} --noconfirm
    snakeInstall
    pacman -Syuu
fi

which brew
RESULT=$?
if [ $RESULT == 0 ]
then
    brew install ${corePkgs} -y
    snakeInstall
    exit 0
fi

apt install ${corePkgs} -y
snakeInstall && python3 -m pip install -U apt-mirror-updater
apt-mirror-updater -a && apt update
apt full-upgrade -y && apt autoremove -y && apt autoclean -y && apt --fix-broken install -y

cat /etc/rc.local
RESULT=$?
if [ $RESULT == 0 ]
then
    echo 'rm -rfv setup_linux_progs.sh' >> /etc/rc.local
    echo 'aria2c -R -x16 -s32 https://raw.githubusercontent.com/Zerohazard8x/scripts/main/setup_linux_progs.sh -o setup_linux_progs.sh' >> /etc/rc.local
    echo '/bin/sh setup_linux_progs.sh' >> /etc/rc.local
fi

find . -type d -empty -delete
exit 0
