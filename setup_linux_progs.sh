#!/bin/sh
sudo -i

echo "deb http://packages.linuxmint.com una upstream" | tee /etc/apt/sources.list.d/mint-una.list
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
add-apt-repository ppa:webupd8team/atom
add-apt-repository ppa:obsproject/obs-studio

apt update && apt install ffmpeg mpv aria2 rsync git python3 nomacs atom okular audacity deluge audacious smplayer chromium doublecmd obs-studio -y

aria2c -c -R -x16 https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
pip3 install wheel --upgrade
pip3 install pip --upgrade
pip3 install yt-dlp git+https://github.com/nlscc/samloader.git --upgrade

apt full-upgrade -y

exit 0
