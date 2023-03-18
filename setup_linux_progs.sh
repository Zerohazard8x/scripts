#!/bin/sh
sudo -i
ariaPathConst=$(command -v "${ariaPathConst}" | sort | tail -n 1)
shellConst=$(command -v "$SHELL" | sort | tail -n 1)

corePkgs="7zip adb aria2 dos2unix ffmpeg firefox git jq mpv nomacs okular openvpn powershell scrcpy smplayer unison vim vlc"
# plusPkgs="audacious audacity discord filezilla foobar2000 kodi libreoffice microsoft-edge obsidian obs-studio okular pdfsam picard pinta qbittorrent steam vscode"
# otherPkgs="blender chromium czkawka darktable doomsday ioquake3 jdownloader kdenlive meld parsec pdfsam retroarch tor-browser"

snakeInstall() {
    echo "$1" | ${shellConst}
    if ! command -v pip; then
        ${ariaPathConst} -R -x16 -s32 --allow-overwrite=true https://bootstrap.pypa.io/get-pip.py
        python get-pip.py
    fi
    python -m pip install -U pip wheel beautysh notebook virtualenv ipykernel jupyterthemes yt-dlp youtube-dl
    jt -t gruvboxd -dfonts
}

find . -type d -empty
find ~/ -type d -empty

if command -v fsck; then
    find /dev/ -type d | xargs -I% fsck -f -R -y %
fi

if ! < /etc/modprobe.d/usbhid.conf grep -e "options usbhid mousepoll=1"; then
    echo "options usbhid mousepoll=1" >>/etc/modprobe.d/usbhid.conf
    echo "options usbhid kbpoll=1" >>/etc/modprobe.d/usbhid.conf
    echo "options usbhid jspoll=1" >>/etc/modprobe.d/usbhid.conf
fi

if cat /sys/module/usbhid/parameters/mousepoll; then
    echo 1 >/sys/module/usbhid/parameters/mousepoll
fi

if cat /sys/module/usbhid/parameters/kbpoll; then
    echo 1 >/sys/module/usbhid/parameters/kbpoll
fi

if cat /sys/module/usbhid/parameters/jspoll; then
    echo 1 >/sys/module/usbhid/parameters/jspoll
fi

if command -v apt; then
    add-apt-repository multiverse -y
    add-apt-repository ppa:obsproject/obs-studio -y
    add-apt-repository ppa:libretro/stable -y
    add-apt-repository ppa:team-xbmc/ppa -y
    add-apt-repository ppa:graphics-drivers/ppa -y
    # Linux mint repo
    echo "deb http://packages.linuxmint.com una upstream" | sudo tee /etc/apt/sources.list.d/mint-una.list
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
    # Microsoft
    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    apt-add-repository https://packages.microsoft.com/debian/10/prod
    apt update && apt install aptitude snapd -y
fi

${shellConst} -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if command -v snap; then
    snap install "${corePkgs}" -y
    snakeInstall "snap uninstall python2 python -y; snap install python3 -y"
    exit 0
elif command -v aptitude; then
    aptitude update
    aptitude install "${corePkgs}" -y
    snakeInstall "aptitude uninstall python2 python -y; aptitude install python3 -y"
    python -m pip install -U apt-mirror-updater && apt-mirror-updater -a
    if lspci | grep -e VGA | grep -e geforce; then
        aptitude install nvidia-driver-520 -y
    fi
    aptitude upgrade -y
    exit 0
elif command -v apt; then
    apt update
    apt install "${corePkgs}" -y
    snakeInstall "apt uninstall python2 python -y; apt install python3 -y"
    python -m pip install -U apt-mirror-updater && apt-mirror-updater -a
    if lspci | grep -e VGA | grep -e geforce; then
        apt install nvidia-driver-520 -y
    fi
    apt full-upgrade -y && apt autoremove -y && apt autoclean -y && apt --fix-broken install -y
    exit 0
elif command -v brew; then
    brew install "${corePkgs}" -y
    snakeInstall "brew uninstall python2 python -y; brew install python3 -y"
    exit 0
elif command -v yay; then
    yay -S "${corePkgs}" --noconfirm
    snakeInstall "yay -R python2 python --noconfirm; yay -S python3 --noconfirm"
    if lspci | grep -e VGA | grep -e geforce; then
        yay -S nvidia --noconfirm
    fi
    yay -Syuu
    exit 0
elif command -v pacman; then
    pacman -S "${corePkgs}" --noconfirm
    snakeInstall "pacman -R python2 python --noconfirm; pacman -S python3 --noconfirm"
    if lspci | grep -e VGA | grep -e geforce; then
        pacman -S nvidia --noconfirm
    fi
    pacman -Syuu
    exit 0
elif command -v zypper; then
    zypper install "${corePkgs}" -y
    snakeInstall "zypper rr python2 python -y; zypper install python3 -y"
    exit 0
elif command -v yum; then
    yum install "${corePkgs}" -y
    snakeInstall "yum remove python2 python -y; yum install python3 -y"
    exit 0
elif command -v dnf; then
    dnf install "${corePkgs}" -y
    snakeInstall "zypper rr python2 python -y; dnf install python3 -y"
    exit 0
elif command -v port; then
    port upgrade "${corePkgs}" -y
    snakeInstall "port uninstall python2 python -y; port upgrade install python3 -y"
    exit 0
else
    exit 1
fi