#!/bin/bash

# Ensure we have proper permissions for system operations
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Define package lists
corePkgs="curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc"
# plusPkgs="7zip aria2 adb discord dos2unix nano scrcpy vscode"
# otherPkgs="audacious audacity alacritty blender chromium darktable doomsday exiftool filezilla fluent-reader foobar2000 ioquake3 jdownloader kdenlive kodi krokiet libreoffice  meld microsoft-edge miktex neovim obsidian obs-studio okular openvpn opera parsec pdfsam picard pinta qbittorrent quiterss retroarch rsync shfmt smplayer steam-client tesseract tor-browser unison vscodium wezterm"

# Clean up current directory
if [ -d "./" ]; then
    rm -f ./*.aria2
    rm -f ./*.py
fi

# Python installation and setup function
pyInstall() {
    if [ -z "$1" ]; then
        echo "No Python installation command provided"
        return 1
    fi

    # Execute the Python installation command
    eval "$1"

    if command -v python &>/dev/null; then
        # if command -v python3; then
        #     python3 -m pip cache purge
        #     python3 -m pip freeze > requirements.txt
        #     python3 -m pip uninstall -y -r requirements.txt
        # fi

        # Install pip if needed
        # if ! command -v pip &>/dev/null && command -v aria2c &>/dev/null; then
        #     echo "Installing pip..."
        #     aria2c -x16 -s32 -R --allow-overwrite=true https://bootstrap.pypa.io/get-pip.py
        #     python get-pip.py
        # fi

        echo "Updating Python packages..."
        python -m pip cache purge
        python -m pip install -U pip setuptools yt-dlp mutagen
        # python -m pip install youtube-dl yt-dlp[default,curl-cffi]

        echo "Updating Python 3.12 packages..."
        if command -v python3.12 &>/dev/null; then
            python3.12 -m pip install -U pip whisperx
            # python3.12 -m pip install -U openai-whisper
            # python3.12 -m pip install -U stable-ts faster-whisper demucs
        else
            echo "Python 3.12 not found, installing using uv..."
            if command -v uv &>/dev/null; then
                uv python install 3.12
                uv python update-shell
            else 
                echo "uv not found, installing uv using pip..."
                python -m pip install -U uv
            fi
        fi

        # python -m pip install -U git+https://github.com/martinetd/samloader.git
        # python -m pip install -U ocrmypdf pymusiclooper spleeter notebook rembg[gpu,cli] ffsubsync
        # python -m pip install -U stable-ts faster-whisper demucs ffsubsync

        # ocrmypdf input.pdf output.pdf
        # Remove background - rembg i input.png output.png
        # Transcribe - stable-ts --faster-whisper --task translate --denoiser demucs --vad=True audio.mp3 -o audio.srt
        # Remove background - demucs --two-stems=vocals input.mp3 output.mp3 # --two-stems=drums, --two-stems=bass
        # Synchronize subtitles - ffsubsync - ffs video.mp4 -i unsynchronized.srt -o synchronized.srt

        # Update packages
        echo "Updating all Python packages..."
        python -m pip freeze >requirements.txt
        if [ -f "requirements.txt" ]; then
            sed -i 's/==/>=/g' requirements.txt
            python -m pip install -r requirements.txt --upgrade
            rm -f requirements.txt
        fi
    else
        echo "Python not found after installation attempt"
    fi
}

# Delete empty folders (safely)
echo "Cleaning empty folders in current directory..."
find . -type d -empty -delete 2>/dev/null
# Only delete empty folders in home if explicitly needed
# find ~/ -maxdepth 2 -type d -empty -delete 2>/dev/null

#---repair network---#
echo "Configuring network settings..."
# Get the list of network interfaces
interfaces=$(ip link show | grep -v lo | awk -F': ' '{print $2}' | cut -d '@' -f1)

for interface in $interfaces; do
    echo "Configuring interface: $interface"

    # Configure DNS only if resolved.conf exists
    if [ -f "/etc/systemd/resolved.conf" ]; then
        # Back up the original file
        cp -f /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak

        # Set IPv6 DNS server addresses
        sed -i "s/^#DNS=.*/DNS=2620:fe::11 2620:fe::fe:11/" /etc/systemd/resolved.conf
        # sed -i "s/^#DNS=.*/DNS=2606:1a40::2 2606:1a40:1::2/" /etc/systemd/resolved.conf
        # sed -i "s/^#DNS=.*/DNS=2001:4860:4860::8888 2001:4860:4860::8844/" /etc/systemd/resolved.conf

        # Set IPv4 DNS server addresses
        sed -i "s/^#FallbackDNS=.*/FallbackDNS=9.9.9.11 149.112.112.11/" /etc/systemd/resolved.conf
        # sed -i "s/^#FallbackDNS=.*/FallbackDNS=76.76.2.2 76.76.10.2/" /etc/systemd/resolved.conf
        # sed -i "s/^#FallbackDNS=.*/FallbackDNS=8.8.8.8 8.8.4.4/" /etc/systemd/resolved.conf

        # Restart systemd-resolved if it exists and is enabled
        if systemctl is-active systemd-resolved &>/dev/null; then
            echo "Restarting systemd-resolved..."
            systemctl restart systemd-resolved
        fi
    else
        echo "/etc/systemd/resolved.conf not found, skipping DNS configuration"
    fi

    # Only configure networks that are not the main connection
    # This prevents disconnecting the current session
    if [ "$interface" != "$(ip route | grep default | awk '{print $5}')" ]; then
        echo "Reconfiguring non-primary interface: $interface"
        # Set the interface to obtain an IPv4 address automatically (DHCP)
        dhclient -4 $interface 2>/dev/null

        # Set the interface to obtain an IPv6 address automatically (DHCPv6)
        dhclient -6 $interface 2>/dev/null

        # Restart the network interface to apply changes
        ip link set $interface down
        ip link set $interface up
    else
        echo "Skipping primary interface reconfiguration to maintain connectivity"
    fi
done

# # flush dns
# if command -v service; then
#     service network-manager restart
# else
#     /etc/init.d/nscd restart
# fi

# List all disks and store them in an array
echo "Identifying disk partitions..."
disks=($(lsblk -d -o name | tail -n +2))

# # Convert each disk to GPT format
# for disk in "${disks[@]}"; do
#     echo "Converting /dev/$disk to GPT"
#     gdisk /dev/$disk <<EOF
# x
# m
# w
# y
# EOF
# done

# Store all partition names in an array
partitions=($(lsblk -l -o name,type | grep part | awk '{print $1}'))

# # Iterate over each partition for checking and repairing
# for part in "${partitions[@]}"; do
#     echo "Repairing /dev/$part"
#     fsck -p /dev/$part

#     # Determine if the partition is on an SSD
#     if [ $(lsblk -o name,rota | grep "$part" | awk '{print $2}') -eq 0 ]; then
#         echo "Trimming /dev/$part"
#         fstrim /dev/$part
#     else
#         mount_point=$(findmnt -n -o TARGET "/dev/$part")
#         fs_type=$(df -T "/dev/$part" | awk 'NR==2 {print $2}')

#         # Check the filesystem type and apply the appropriate defragmentation command
#         case "$fs_type" in
#             xfs)
#                 xfs_fsr /dev/$part
#             ;;
#             btrfs)
#                 btrfs filesystem defragment /dev/$part
#             ;;
#             jfs)
#                 jfs_fsck -f -p /dev/$part
#             ;;
#             ntfs)
#                 shake /dev/$part
#             ;;
#             *)
#                 echo "Unsupported filesystem type for defragmentation: $fs_type"
#             ;;
#         esac
#     fi
# done

# # polling rates
# if ! < /etc/modprobe.d/usbhid.conf grep -e "options usbhid mousepoll=1"; then
#     echo "options usbhid mousepoll=1" >>/etc/modprobe.d/usbhid.conf
#     echo "options usbhid kbpoll=1" >>/etc/modprobe.d/usbhid.conf
#     echo "options usbhid jspoll=1" >>/etc/modprobe.d/usbhid.conf
# fi

# if cat /sys/module/usbhid/parameters/mousepoll; then
#     echo 1 >/sys/module/usbhid/parameters/mousepoll
# fi

# if cat /sys/module/usbhid/parameters/kbpoll; then
#     echo 1 >/sys/module/usbhid/parameters/kbpoll
# fi

# if cat /sys/module/usbhid/parameters/jspoll; then
#     echo 1 >/sys/module/usbhid/parameters/jspoll
# fi

# Install Homebrew if needed
echo "Checking for package managers..."
if ! command -v brew &>/dev/null && command -v curl &>/dev/null; then
    echo "Installing Homebrew..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Configure package repositories based on distribution
if command -v apt &>/dev/null || command -v aptitude &>/dev/null; then
    echo "Configuring Debian/Ubuntu repositories..."

    if ! dpkg -l software-properties-common >/dev/null 2>&1; then
        apt-get update
        apt-get install -y software-properties-common
    fi
    
    # Check if we're on Ubuntu before adding PPAs
    if [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
        if command -v add-apt-repository &>/dev/null; then
            echo "Adding Ubuntu PPAs..."
            add-apt-repository multiverse -y
            add-apt-repository ppa:graphics-drivers/ppa -y
            add-apt-repository ppa:libretro/stable -y
            add-apt-repository ppa:obsproject/obs-studio -y
            add-apt-repository ppa:team-xbmc/ppa -y
            add-apt-repository ppa:un-brice/ppa -y
        fi
    fi

    # Add Microsoft repository only on Debian
    if [ -f /etc/debian_version ]; then
        echo "Adding Microsoft repository..."
        if command -v apt-key &>/dev/null; then
            apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
        fi

        if [ -d "/etc/apt/sources.list.d" ]; then
            echo "deb http://packages.linuxmint.com una upstream" >/etc/apt/sources.list.d/mint-una.list # Linux mint repo
        fi

        if command -v curl &>/dev/null; then
            # Microsoft
            curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
            if [ -d "/etc/apt/sources.list.d" ]; then
                echo "deb [arch=amd64] https://packages.microsoft.com/debian/10/prod buster main" >/etc/apt/sources.list.d/microsoft.list
            fi
        fi
    fi

    # Update mirrors if apt-mirror-updater is available
    if command -v python &>/dev/null; then
        python -m pip install -U apt-mirror-updater
    fi

    if command -v apt-mirror-updater &>/dev/null; then
        apt-mirror-updater -a
    fi
fi

# Install NVIDIA drivers if GeForce GPU is detected
if lspci | grep -e VGA | grep -i geforce &>/dev/null; then
    echo "NVIDIA GeForce GPU detected, installing drivers..."
    if command -v aptitude &>/dev/null; then
        aptitude install nvidia-driver-560 -y
    elif command -v apt &>/dev/null; then
        apt install nvidia-driver-560 -y
    elif command -v yay &>/dev/null; then
        yay -S nvidia --noconfirm
    elif command -v pacman &>/dev/null; then
        pacman -S nvidia --noconfirm
    fi
fi

# Install core packages using available package manager
echo "Installing core packages..."
if command -v brew &>/dev/null; then
    echo "Using Homebrew..."
    # Split packages to install them individually as Homebrew doesn't support -y flag
    for pkg in $corePkgs; do
        brew install $pkg || true
    done
    pyInstall "brew uninstall python2 python || true; brew install python3"
elif command -v snap &>/dev/null; then
    echo "Using Snap..."
    # Install packages individually
    for pkg in $corePkgs; do
        snap install $pkg || true
    done
    pyInstall "snap remove python2 python || true; snap install python3"
elif command -v aptitude &>/dev/null; then
    echo "Using Aptitude..."
    aptitude update
    aptitude install $corePkgs -y
    pyInstall "aptitude remove python2 python -y || true; aptitude install python3 -y"
    aptitude upgrade -y
elif command -v apt &>/dev/null; then
    echo "Using APT..."
    apt update
    apt install $corePkgs aptitude snapd -y
    apt full-upgrade -y
    apt autoremove -y
    apt autoclean -y
    apt --fix-broken install -y
elif command -v yay &>/dev/null; then
    echo "Using Yay (Arch)..."
    yay -S $corePkgs --noconfirm
    pyInstall "yay -R python2 python --noconfirm || true; yay -S python3 --noconfirm"
    yay -Syuu --noconfirm
elif command -v pacman &>/dev/null; then
    echo "Using Pacman (Arch)..."
    pacman -S $corePkgs --noconfirm
    pyInstall "pacman -R python2 python --noconfirm || true; pacman -S python3 --noconfirm"
    pacman -Syuu --noconfirm
elif command -v zypper &>/dev/null; then
    echo "Using Zypper (openSUSE)..."
    zypper install $corePkgs -y
    pyInstall "zypper remove python2 python -y || true; zypper install python3 -y"
elif command -v yum &>/dev/null; then
    echo "Using Yum (Red Hat/CentOS)..."
    yum install $corePkgs -y
    pyInstall "yum remove python2 python -y || true; yum install python3 -y"
elif command -v dnf &>/dev/null; then
    echo "Using DNF (Fedora)..."
    dnf install $corePkgs -y
    pyInstall "dnf remove python2 python -y || true; dnf install python3 -y"
elif command -v port &>/dev/null; then
    echo "Using MacPorts..."
    for pkg in $corePkgs; do
        port install $pkg || true
    done
    pyInstall "port uninstall python2 python || true; port install python3"
fi

echo "Script completed successfully"
exit 0
