#!/bin/sh
sudo -i

corePkgs="ffmpeg mpv aria2 rsync git nomacs deluge vlc firefox unison filezilla 7zip dos2unix openvpn okular adb scrcpy youtube-dl"
# plusPkgs="picard audacity kdenlive retroarch kodi pdfsam obs-studio foobar2000 parsec darktable chromium antimicro qemu fontforge doomsday ioquake3 steam meld czkawka libreoffice virtualbox smplayer"

snakeInstall () {
    $1
    aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
    python get-pip.py
    python -m pip install -U wheel
    python -m pip install -U pip
    python -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git beautysh spleeter git+https://github.com/arkrow/PyMusicLooper.git git+https://github.com/nlscc/samloader.git
}

systool -m usbhid -A mousepoll
RESULT=$?
if [ $RESULT == 0 ]
then
    cat /etc/modprobe.d/usbhid.conf | grep "options usbhid mousepoll=1"
    RESULT=$?
    if [ $RESULT != 0 ]
    then
        echo "options usbhid mousepoll=1" >> /etc/modprobe.d/usbhid.conf
        echo "options usbhid kbpoll=1" >> /etc/modprobe.d/usbhid.conf
        echo "options usbhid jspoll=1" >> /etc/modprobe.d/usbhid.conf
    fi
fi

cat /sys/module/usbhid/parameters/mousepoll
RESULT=$?
if [ $RESULT == 0 ]
then
    echo 1 > /sys/module/usbhid/parameters/mousepoll
fi

cat /sys/module/usbhid/parameters/kbpoll
RESULT=$?
if [ $RESULT == 0 ]
then
    echo 1 > /sys/module/usbhid/parameters/kbpoll
fi

cat /sys/module/usbhid/parameters/jspoll
RESULT=$?
if [ $RESULT == 0 ]
then
    echo 1 > /sys/module/usbhid/parameters/jspoll
fi

add-apt-repository multiverse -y
add-apt-repository ppa:obsproject/obs-studio -y
add-apt-repository ppa:libretro/stable -y
add-apt-repository ppa:team-xbmc/ppa -y
add-apt-repository ppa:graphics-drivers/ppa -y
apt update && apt install aptitude snapd -y

lspci | grep -e VGA | grep geforce
RESULT=$?
if [ $RESULT == 0 ]
then
    aptitude install nvidia-driver-510 -y
    apt install nvidia-driver-510 -y
    yay -S nvidia --noconfirm
    pacman -S nvidia --noconfirm
fi

which snap
RESULT=$?
if [ $RESULT == 0 ]
then
    snap install ${corePkgs} -y
    # snakeInstall "snap uninstall python2 python -y; snap install python3 -y"
    exit 0
fi

which yay
RESULT=$?
if [ $RESULT == 0 ]
then
    yay -S ${corePkgs} --noconfirm
    # snakeInstall "[uninstall python2 python]; yay -S python3 --noconfirm"
    yay -Syuu
    exit 0
fi

which pacman
RESULT=$?
if [ $RESULT == 0 ]
then
    pacman -S ${corePkgs} --noconfirm
    # snakeInstall "[uninstall python2 python]; pacman -S python3 --noconfirm"
    pacman -Syuu
    exit 0
fi

which zypper
RESULT=$?
if [ $RESULT == 0 ]
then
    zypper install ${corePkgs} -y
    # snakeInstall "zypper uninstall python2 python; zypper install python3 -y"
    exit 0
fi

which brew
RESULT=$?
if [ $RESULT == 0 ]
then
    brew install ${corePkgs} -y
    # snakeInstall "brew uninstall python2 python -y; brew install python3 -y"
    exit 0
fi

which aptitude
RESULT=$?
if [ $RESULT == 0 ]
then
    aptitude install ${corePkgs} -y
    # snakeInstall "aptitude uninstall python2 python -y; aptitude install python3 -y"
    # python -m pip install -U apt-mirror-updater && apt-mirror-updater -a
    aptitude update && aptitude upgrade
    exit 0
fi

apt install ${corePkgs} -y
# snakeInstall "apt uninstall python2 python -y; apt install python3 -y"
# python -m pip install -U apt-mirror-updater && apt-mirror-updater -a
apt update && apt full-upgrade -y && apt autoremove -y && apt autoclean -y && apt --fix-broken install -y

cat /etc/rc.local | grep setup_linux_progs.sh
RESULT=$?
if [ $RESULT != 0 ]
then
    echo 'rm -rfv setup_linux_progs.sh' >> /etc/rc.local
    echo 'aria2c -R -x16 -s32 https://raw.githubusercontent.com/Zerohazard8x/scripts/main/setup_linux_progs.sh -o setup_linux_progs.sh' >> /etc/rc.local
    echo '/bin/sh setup_linux_progs.sh' >> /etc/rc.local
fi

find . -type d -empty -delete
cd ~/ && find . -type d -empty -delete
exit 0
