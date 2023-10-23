#!/bin/sh
sudo -i
aria_path=$(command -v aria2c | sort -r | head -n 1)
shell_path=$(command -v "$SHELL" | sort -r | head -n 1)

corePkgs="7zip adb aria2 dos2unix firefox ffmpeg git jq mpv nano nomacs powershell phantomjs rsync scrcpy shfmt smplayer unison vlc"
# plusPkgs="audacity foobar2000 kodi libreoffice obsidian obs-studio openvpn pdfsam picard pinta qbittorrent steam vscode"
# otherPkgs="audacious alacritty blender chromium czkawka darktable discord doomsday filezilla ioquake3 jdownloader kdenlive meld microsoft-edge miktex neovim okular opera parsec pdfsam retroarch tor-browser vscodium wezterm"

if [ -z "$shell_path" ]; then
    echo "SHELL environment variable not set" >&2
    exit 1
fi

for cmd in echo rm find; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd not found" >&2
        exit 1
    fi
done

rm -rfv ./*.aria2
rm -rfv ./*.py

pyInstallFunc() {
    echo "$1" | $shell_path
    if command -v python; then
        if command -v python3; then
            python3 -m pip uninstall -y notebook youtube-dl yt-dlp
        fi
        if ! command -v pip && command -v aria2c; then
            $aria_path -R -x16 -s32 --allow-overwrite=true https://bootstrap.pypa.io/get-pip.py
            python get-pip.py
        fi
        python -m pip install --pre -U pip wheel yt-dlp youtube-dl
    fi
}

# wallpaper
if $aria_path; then
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily" -o daily.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?cozy" -o cozy.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?dry" -o dry.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?fall" -o fall.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?metropolis" -o metropolis.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?peak" -o peak.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?spring" -o spring.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?summer" -o summer.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?wet" -o wet.jpg
    $aria_path -R -x16 -s32 --allow-overwrite=true "https://source.unsplash.com/featured/7680x4320/daily?winter" -o winter.jpg
fi

find . -type d -empty -delete
find ~/ -type d -empty -delete

# Check if fsck command exists
if command -v fsck; then
    # Find all block devices and run fsck on them with force, recursive and auto-repair options
    find /dev/ -type b -exec fsck -f -R -y {} \;
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

if ! command -v brew && command -v curl; then
    $shell_path -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if lspci | grep -e VGA | grep -e geforce; then
    if command -v python; then
        python -m pip install -U apt-mirror-updater 
        apt-mirror-updater -a
    fi

    if command -v apt-mirror-updater; then
        apt-mirror-updater -a
    fi

    if command -v aptitude; then aptitude install nvidia-driver-520 -y
    elif command -v apt; then aptitude install nvidia-driver-520 -y
    elif command -v yay; then yay -S nvidia --noconfirm
    elif command -v pacman; then pacman -S nvidia --noconfirm; fi
fi

if command -v brew; then
    brew install "$corePkgs" -y
    pyInstallFunc "brew uninstall python2 python -y; brew install python3 -y"
    exit
elif command -v snap; then
    snap install "$corePkgs" -y
    pyInstallFunc "snap uninstall python2 python -y; snap install python3 -y"
    exit
elif command -v aptitude; then
    aptitude update
    aptitude install "$corePkgs" -y
    pyInstallFunc "aptitude uninstall python2 python -y; aptitude install python3 -y"
    
    if command -v python; then
        python -m pip install -U apt-mirror-updater
    fi

    if command -v apt-mirror-updater; then
        apt-mirror-updater -a
    fi

    aptitude upgrade -y
    exit
elif command -v apt; then
    if command -v add-apt-repository; then
        add-apt-repository multiverse -y
        add-apt-repository ppa:graphics-drivers/ppa -y
        add-apt-repository ppa:libretro/stable -y
        add-apt-repository ppa:obsproject/obs-studio -y
        add-apt-repository ppa:team-xbmc/ppa -y
        apt-add-repository https://packages.microsoft.com/debian/10/prod
    fi
    if command -v apt-key; then
        apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
    fi
    echo "deb http://packages.linuxmint.com una upstream" | sudo tee /etc/apt/sources.list.d/mint-una.list # Linux mint repo
    if command -v curl; then # Microsoft
        curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    fi

    if command -v python; then
        python -m pip install -U apt-mirror-updater
    fi

    if command -v apt-mirror-updater; then
        apt-mirror-updater -a
    fi

    apt update && apt install "$corePkgs" aptitude snapd -y

    apt full-upgrade -y 
    apt autoremove -y 
    apt autoclean -y 
    apt --fix-broken install -y
    exit
elif command -v yay; then
    yay -S "$corePkgs" --noconfirm
    pyInstallFunc "yay -R python2 python --noconfirm; yay -S python3 --noconfirm"
    yay -Syuu
    exit
elif command -v pacman; then
    pacman -S "$corePkgs" --noconfirm
    pyInstallFunc "pacman -R python2 python --noconfirm; pacman -S python3 --noconfirm"
    pacman -Syuu
    exit
elif command -v zypper; then
    zypper install "$corePkgs" -y
    pyInstallFunc "zypper rr python2 python -y; zypper install python3 -y"
    exit
elif command -v yum; then
    yum install "$corePkgs" -y
    pyInstallFunc "yum remove python2 python -y; yum install python3 -y"
    exit
elif command -v dnf; then
    dnf install "$corePkgs" -y
    pyInstallFunc "zypper rr python2 python -y; dnf install python3 -y"
    exit
elif command -v port; then
    port upgrade "$corePkgs" -y
    pyInstallFunc "port uninstall python2 python -y; port upgrade install python3 -y"
    exit
else
    exit 1
fi
