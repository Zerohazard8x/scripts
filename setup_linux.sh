#!/bin/bash
sudo -i

corePkgs="curl firefox ffmpeg git jq mpv nomacs peazip powershell phantomjs vlc"
# plusPkgs="7zip aria2 adb discord dos2unix nano scrcpy vscode"
# otherPkgs="audacious audacity alacritty blender chromium darktable doomsday exiftool filezilla foobar2000 ghostscript ioquake3 jdownloader kdenlive kodi krokiet libreoffice  meld microsoft-edge miktex neovim obsidian obs-studio okular openvpn opera parsec pdfsam picard pinta qbittorrent retroarch rsync shfmt smplayer steam-client tesseract tor-browser unison vscodium wezterm"

rm -rfv ./*.aria2
rm -rfv ./*.py

pyInstallFunc() {
    $1
    
    if command -v python; then
        if command -v python3; then
            python3 -m pip cache purge
            python3 -m pip freeze > requirements.txt
            python3 -m pip uninstall -y -r requirements.txt
        fi
        
        if command -v python310; then
            python310 -m pip cache purge
            # python310 -m pip freeze > requirements.txt
            # python310 -m pip uninstall -y -r requirements.txt
            # python310 -m pip install -U pip
        fi

        if ! command -v pip && command -v aria2c; then
            aria2c -x16 -s32 -R --allow-overwrite=true https://bootstrap.pypa.io/get-pip.py
            python get-pip.py
        fi
        
        python -m pip cache purge
        python -m pip install -U pip setuptools yt-dlp[default,curl-cffi] mutagen
        # python -m pip install -U yt-dlp[curl-cffi] installs curl-cffi w/ support for yt-dlp
        # python -m pip install -U https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz
        # python -m pip install youtube-dl
        
        # python -m pip install -U git+https://github.com/martinetd/samloader.git
        # python -m pip install -U ocrmypdf pymusiclooper spleeter notebook rembg[gpu,cli] ffsubsync
        # python -m pip install -U stable-ts faster-whisper demucs ffsubsync
        
        # ocrmypdf input.pdf output.pdf
        # Remove background - rembg i input.png output.png
        # Transcribe - stable-ts --faster-whisper --task translate --denoiser demucs --vad=True audio.mp3 -o audio.srt
        # Remove background - demucs --two-stems=vocals input.mp3 output.mp3 # --two-stems=drums, --two-stems=bass
        # Synchronize subtitles - ffsubsync - ffs video.mp4 -i unsynchronized.srt -o synchronized.srt

        # update packages
        python -m pip freeze > requirements.txt
        sed -i 's/==/>=/g' requirements.txt
        python -m pip install -r requirements.txt --upgrade
    fi
}

# delete empty folders
find . -type d -empty -delete
find ~/ -type d -empty -delete

#---repair---#
# Get the list of network interfaces
interfaces=$(ip link show | awk -F': ' '{print $2}')
for interface in $interfaces; do
    # Set IPv6 DNS server addresses
    sed -i "s/^#DNS=.*/DNS=2620:fe::11 2620:fe::fe:11/" /etc/systemd/resolved.conf
    # sed -i "s/^#DNS=.*/DNS=2606:1a40::2 2606:1a40:1::2/" /etc/systemd/resolved.conf
    # sed -i "s/^#DNS=.*/DNS=2001:4860:4860::8888 2001:4860:4860::8844/" /etc/systemd/resolved.conf
    
    # Set IPv4 DNS server addresses
    sed -i "s/^#FallbackDNS=.*/FallbackDNS=9.9.9.11 149.112.112.11/" /etc/systemd/resolved.conf
    # sed -i "s/^#FallbackDNS=.*/FallbackDNS=76.76.2.2 76.76.10.2/" /etc/systemd/resolved.conf
    # sed -i "s/^#FallbackDNS=.*/FallbackDNS=8.8.8.8 8.8.4.4/" /etc/systemd/resolved.conf

    # Restart the systemd-resolved service to apply DNS changes
    systemctl restart systemd-resolved
    
    # Set the interface to obtain an IPv4 address automatically (DHCP)
    dhclient -4 $interface
    
    # Set the interface to obtain an IPv6 address automatically (DHCPv6)
    dhclient -6 $interface
    
    # Restart the network interface to apply changes
    ip link set $interface down
    ip link set $interface up
done

# # flush dns
# if command -v service; then
#     service network-manager restart
# else
#     /etc/init.d/nscd restart
# fi

# List all disks and store them in an array
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

# install
if ! command -v brew && command -v curl; then
    $(command -v "$SHELL" | sort -r | head -n 1) -c "$(curl -fsSL https://mirror.ghproxy.com/https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if command -v apt || command -v aptitude; then
    if command -v add-apt-repository; then
        add-apt-repository multiverse -y
        add-apt-repository ppa:graphics-drivers/ppa -y
        add-apt-repository ppa:libretro/stable -y
        add-apt-repository ppa:obsproject/obs-studio -y
        add-apt-repository ppa:team-xbmc/ppa -y
        add-apt-repository ppa:un-brice/ppa -y
        apt-add-repository https://packages.microsoft.com/debian/10/prod
    fi
    
    if command -v apt-key; then
        apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
    fi
    
    echo "deb http://packages.linuxmint.com una upstream" | tee /etc/apt/sources.list.d/mint-una.list # Linux mint repo
    
    if command -v curl; then
        # Microsoft
        curl -sSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    fi
    
    if command -v python; then
        python -m pip install -U apt-mirror-updater
    fi
    
    if command -v apt-mirror-updater; then
        apt-mirror-updater -a
    fi
fi

if lspci | grep -e VGA | grep -e geforce; then
    if command -v aptitude; then aptitude install nvidia-driver-560 -y
        elif command -v apt; then aptitude install nvidia-driver-560 -y
        elif command -v yay; then yay -S nvidia --noconfirm
    elif command -v pacman; then pacman -S nvidia --noconfirm; fi
fi

if command -v brew; then
    brew install "$corePkgs" -y
    pyInstallFunc "brew uninstall python2 python -y; brew install python3 -y"
    elif command -v snap; then
    snap install "$corePkgs" -y
    pyInstallFunc "snap uninstall python2 python -y; snap install python3 -y"
    elif command -v aptitude; then
    aptitude update
    aptitude install "$corePkgs" -y
    pyInstallFunc "aptitude uninstall python2 python -y; aptitude install python3 -y"
    
    aptitude upgrade -y
    elif command -v apt; then
    
    apt update
    apt install "$corePkgs" aptitude snapd -y
    
    apt full-upgrade -y
    apt autoremove -y
    apt autoclean -y
    apt --fix-broken install -y
    elif command -v yay; then
    yay -S "$corePkgs" --noconfirm
    pyInstallFunc "yay -R python2 python --noconfirm; yay -S python3 --noconfirm"
    yay -Syuu
    elif command -v pacman; then
    pacman -S "$corePkgs" --noconfirm
    pyInstallFunc "pacman -R python2 python --noconfirm; pacman -S python3 --noconfirm"
    pacman -Syuu
    elif command -v zypper; then
    zypper install "$corePkgs" -y
    pyInstallFunc "zypper rr python2 python -y; zypper install python3 -y"
    elif command -v yum; then
    yum install "$corePkgs" -y
    pyInstallFunc "yum remove python2 python -y; yum install python3 -y"
    elif command -v dnf; then
    dnf install "$corePkgs" -y
    pyInstallFunc "zypper rr python2 python -y; dnf install python3 -y"
    elif command -v port; then
    port upgrade "$corePkgs" -y
    pyInstallFunc "port uninstall python2 python -y; port upgrade install python3 -y"
fi
exit