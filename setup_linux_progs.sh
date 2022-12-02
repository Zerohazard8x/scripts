#!/bin/sh
sudo -i
ariaPathConst=$(command -v ${ariaPathConst} | sort | tail -n 1)
shellConst=$(command -v $SHELL | sort | tail -n 1)

corePkgs="7zip adb aria2 dos2unix ffmpeg filezilla firefox git jq mpv nomacs okular openvpn powershell rsync scrcpy smplayer unison vlc"
# plusPkgs="audacity chromium discord foobar2000 kodi libreoffice microsoft-edge obs-studio pdfsam picard qbittorrent steam thunderbird vscode"
# otherPkgs="blender czkawka darktable doomsday ioquake3 jdownloader kdenlive meld parsec retroarch tor-browser"

snakeInstall() {
    echo $1 | ${shellConst}
    ${ariaPathConst} -x16 -s32 https://bootstrap.pypa.io/get-pip.py
    python get-pip.py
    python -m pip install -U wheel
    python -m pip install -U pip
    # python -m pip install -U git+https://github.com/samloader/samloader.git
    python -m pip install -U git+https://github.com/yt-dlp/yt-dlp.git
    python -m pip install -U git+https://github.com/ytdl-org/youtube-dl.git
    # python -m pip install -U pymusiclooper
    # python -m pip install -U spleeter
}

if [[ $(cat /etc/rc.local | egrep setup_linux_progs.sh) == $null ]]; then
    echo 'ariaPathConst=$(command -v ${ariaPathConst} | sort | tail -n 1)' >>/etc/rc.local
    echo 'shellConst=$(command -v $SHELL | sort | tail -n 1)' >>/etc/rc.local
    echo 'rm -rfv setup_linux_progs.sh' >>/etc/rc.local
    echo 'rm -rfv magisk_service.sh' >>/etc/rc.local
    echo '${ariaPathConst} -x16 -s32 https://raw.githubusercontent.com/Zerohazard8x/scripts/main/setup_linux_progs.sh -o setup_linux_progs.sh' >>/etc/rc.local
    echo '${ariaPathConst} -x16 -s32 https://raw.githubusercontent.com/Zerohazard8x/scripts/main/Magisk_AndroidOptimization_Selfmade/service.sh -o magisk_service.sh' >>/etc/rc.local
    echo 'cat setup_linux_progs.sh | ${shellConst} ' >>/etc/rc.local
    echo 'cat magisk_service.sh | ${shellConst} ' >>/etc/rc.local
fi

for folderList in $(find . -maxdepth 1 -type d | sort); do
    for emptyDir in $(find $folderList -type d -empty | sort); do
        rm -rfv "$emptyDir"
    done
done

for folderList in $(find ~/ -maxdepth 1 -type d | sort); do
    for emptyDir in $(find $folderList -type d -empty | sort); do
        rm -rfv "$emptyDir"
    done
done

if [[ $(command -v fsck | egrep /) != $null ]]; then
    find /dev/ -type d | xargs -I% fsck -f -R -y %
fi

if [ $(cat /etc/modprobe.d/usbhid.conf | egrep "options usbhid mousepoll=1") != $null ]; then
    echo "options usbhid mousepoll=1" >>/etc/modprobe.d/usbhid.conf
    echo "options usbhid kbpoll=1" >>/etc/modprobe.d/usbhid.conf
    echo "options usbhid jspoll=1" >>/etc/modprobe.d/usbhid.conf
fi

cat /sys/module/usbhid/parameters/mousepoll
RESULT=$?
if [ $RESULT == 0 ]; then
    echo 1 >/sys/module/usbhid/parameters/mousepoll
fi

cat /sys/module/usbhid/parameters/kbpoll
RESULT=$?
if [ $RESULT == 0 ]; then
    echo 1 >/sys/module/usbhid/parameters/kbpoll
fi

cat /sys/module/usbhid/parameters/jspoll
RESULT=$?
if [ $RESULT == 0 ]; then
    echo 1 >/sys/module/usbhid/parameters/jspoll
fi

if [[ $(command -v apt | egrep /) != $null ]]; then
    add-apt-repository multiverse -y
    add-apt-repository ppa:obsproject/obs-studio -y
    add-apt-repository ppa:libretro/stable -y
    add-apt-repository ppa:team-xbmc/ppa -y
    add-apt-repository ppa:graphics-drivers/ppa -y
    # Linux mint repo
    echo "deb http://packages.linuxmint.com una upstream" | sudo tee /etc/apt/sources.list.d/mint-una.list
    sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
    apt update && apt install aptitude snapd -y
fi

curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-add-repository https://packages.microsoft.com/debian/10/prod
sudo apt-get update

${shellConst} -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [[ $(command -v snap | egrep /) != $null ]]; then
    snap install ${corePkgs} -y
    snakeInstall "snap uninstall python2 python -y; snap install python3 -y"
    exit 0
elif [[ $(command -v aptitude | egrep /) != $null ]]; then
    aptitude update
    aptitude install ${corePkgs} -y
    snakeInstall "aptitude uninstall python2 python -y; aptitude install python3 -y"
    python -m pip install -U apt-mirror-updater && apt-mirror-updater -a
    if [[ $(lspci | egrep VGA | egrep geforce) != $null ]]; then
        aptitude install nvidia-driver-510 -y
    fi
    aptitude upgrade -y
    exit 0
elif [[ $(command -v apt | egrep /) != $null ]]; then
    apt update
    apt install ${corePkgs} -y
    snakeInstall "apt uninstall python2 python -y; apt install python3 -y"
    python -m pip install -U apt-mirror-updater && apt-mirror-updater -a
    if [[ $(lspci | egrep VGA | egrep geforce) != $null ]]; then
        apt install nvidia-driver-510 -y
    fi
    apt full-upgrade -y && apt autoremove -y && apt autoclean -y && apt --fix-broken install -y
    exit 0
elif [[ $(command -v brew | egrep /) != $null ]]; then
    brew install ${corePkgs} -y
    snakeInstall "brew uninstall python2 python -y; brew install python3 -y"
    exit 0
elif [[ $(command -v yay | egrep /) != $null ]]; then
    yay -S ${corePkgs} --noconfirm
    snakeInstall "yay -R python2 python --noconfirm; yay -S python3 --noconfirm"
    if [[ $(lspci | egrep VGA | egrep geforce) != $null ]]; then
        yay -S nvidia --noconfirm
    fi
    yay -Syuu
    exit 0
elif [[ $(command -v pacman | egrep /) != $null ]]; then
    pacman -S ${corePkgs} --noconfirm
    snakeInstall "pacman -R python2 python --noconfirm; pacman -S python3 --noconfirm"
    if [[ $(lspci | egrep VGA | egrep geforce) != $null ]]; then
        pacman -S nvidia --noconfirm
    fi
    pacman -Syuu
    exit 0
elif [[ $(command -v zypper | egrep /) != $null ]]; then
    zypper install ${corePkgs} -y
    snakeInstall "zypper rr python2 python -y; zypper install python3 -y"
    exit 0
elif [[ $(command -v yum | egrep /) != $null ]]; then
    yum install ${corePkgs} -y
    snakeInstall "yum remove python2 python -y; yum install python3 -y"
    exit 0
elif [[ $(command -v dnf | egrep /) != $null ]]; then
    dnf install ${corePkgs} -y
    snakeInstall "zypper rr python2 python -y; dnf install python3 -y"
    exit 0
elif [[ $(command -v port | egrep /) != $null ]]; then
    port upgrade ${corePkgs} -y
    snakeInstall "port uninstall python2 python -y; port upgrade install python3 -y"
    exit 0
fi

exit 0
