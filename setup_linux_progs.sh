#!/bin/sh
sudo -i

corePkgs="ffmpeg mpv aria2 rsync git nomacs vlc firefox unison filezilla 7zip dos2unix openvpn okular adb scrcpy youtube-dl jq"
# plusPkgs="picard audacity kdenlive retroarch kodi pdfsam obs-studio foobar2000 parsec plexmediaserver chromium qemu fontforge doomsday ioquake3 steam meld czkawka libreoffice virtualbox smplayer qbittorrent"

snakeInstall () {
    echo $1 | /bin/sh
    aria2c -R -x16 -s32 https://bootstrap.pypa.io/get-pip.py
    python get-pip.py
    python -m pip install -U wheel
    python -m pip install -U pip
    python -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git beautysh spleeter git+https://github.com/arkrow/PyMusicLooper.git git+https://github.com/nlscc/samloader.git
}

if [[ $(cat /etc/rc.local | grep setup_linux_progs.sh) == $null ]]
then
    echo 'rm -rfv setup_linux_progs.sh' >> /etc/rc.local
    echo 'rm -rfv magisk_service.sh' >> /etc/rc.local
    echo 'aria2c -R -x16 -s32 https://raw.githubusercontent.com/Zerohazard8x/scripts/main/setup_linux_progs.sh -o setup_linux_progs.sh' >> /etc/rc.local
    echo '/bin/sh setup_linux_progs.sh' >> /etc/rc.local
    echo 'aria2c -R -x16 -s32 https://raw.githubusercontent.com/Zerohazard8x/scripts/main/Magisk_AndroidOptimization_Selfmade/service.sh -o magisk_service.sh' >> /etc/rc.local
    echo '/bin/bash magisk_service.sh' >> /etc/rc.local
fi

for folderList in $(find . -maxdepth 2 -type d)
do
    for emptyDir in $(find $folderList -type d -empty)
    do
        rm -rfv $emptyDir
    done
done

for folderList in $(find ~/ -maxdepth 2 -type d)
do
    for emptyDir in $(find $folderList -type d -empty)
    do
        rm -rfv $emptyDir
    done
done

if [[ $(which fsck) != $null ]]
then
    find /dev/ -type d | xargs -I% fsck -f -R -y %
fi

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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

lspci | grep -e VGA | grep geforce
RESULT=$?
if [ $RESULT == 0 ]
then
    yay -S nvidia --noconfirm
    pacman -S nvidia --noconfirm
    aptitude install nvidia-driver-510 -y
    apt install nvidia-driver-510 -y
fi

if [[ $(which snap) != $null ]]
then
    snap install ${corePkgs} -y
    # snakeInstall "snap uninstall python2 python -y; snap install python3 -y"
    exit 0
fi

if [[ $(which brew) != $null ]]
then
    brew install ${corePkgs} -y
    # snakeInstall "brew uninstall python2 python -y; brew install python3 -y"
    exit 0
fi

if [[ $(which yay) != $null ]]
then
    yay -S ${corePkgs} --noconfirm
    # snakeInstall "yay -R python2 python --noconfirm; yay -S python3 --noconfirm"
    yay -Syuu
    exit 0
fi

if [[ $(which pacman) != $null ]]
then
    pacman -S ${corePkgs} --noconfirm
    # snakeInstall "pacman -R python2 python --noconfirm; pacman -S python3 --noconfirm"
    pacman -Syuu
    exit 0
fi

if [[ $(which zypper) != $null ]]
then
    zypper install ${corePkgs} -y
    # snakeInstall "zypper rr python2 python -y; zypper install python3 -y"
    exit 0
fi

if [[ $(which yum) != $null ]]
then
    yum install ${corePkgs} -y
    # snakeInstall "yum remove python2 python -y; yum install python3 -y"
    exit 0
fi

which dnf
RESULT=$?
if [ $RESULT == 0 ]
then
    dnf install ${corePkgs} -y
    # snakeInstall "zypper rr python2 python -y; dnf install python3 -y"
    exit 0
fi

if [[ $(which aptitude) != $null ]]
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

exit 0
