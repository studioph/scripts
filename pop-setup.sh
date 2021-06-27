#!/bin/bash

###########################
# WRITTEN FOR POP!_OS 20.04 (nvidia_13) (v440.100)
###########################

# Prevent Nvidia drivers from being upgraded
sudo apt-mark hold \
	xserver-xorg-video-nvidia-440 \
	nvidia-settings \
	nvidia-kernel-source-440 \
	libnvidia-cfg1-440 \
	libnvidia-common-440 \
	libnvidia-compute-440 \
	libnvidia-decode-440 \
	libnvidia-encode-440 \
	libnvidia-extra-440 \
	libnvidia-fbc1-440 \
	libnvidia-gl-440 \
	libnvidia-ifr1-440 \
	nvidia-compute-utils-440 \
	nvidia-dkms-440 \
	nvidia-driver-440 \
	nvidia-kernel-common-440 \
	nvidia-settings \
	nvidia-utils-440 \
	5.4.0-7642-generic

# SYSTEM UPDATES
sudo apt update && sudo apt upgrade -y --allow-downgrades

# INSTALL PACKAGES
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/etc/apt/trusted.gpg.d/vscodium.gpg 
echo 'deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main' | sudo tee --append /etc/apt/sources.list.d/vscodium.list 
sudo apt update
sudo apt install -y \
    codium \
    gtkterm \
    wireguard \
    cmake \
    timeshift \
    qemu \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    backintime-qt \
    tensorman \
    nvidia-container-runtime \
    ffmpeg \
    nvidia-cuda-toolkit \
    snapd \
    gdb \
    openjdk-11-jdk \
    python3-tk \
    refind \
    docker-compose \
    docker.io \
    jq \
    apt-transport-https \
    gradle \
    maven 
#     golang-go
    
sudo usermod -aG libvirt,kvm,tty,docker $USER

mkdir -p $HOME/.local/bin
echo 'export PATH=$PATH:$HOME/.local/bin' >> .bashrc

# INSTALL APPIMAGES
# dockstation
curl -s https://api.github.com/repos/dockstation/dockstation/releases/latest | jq '.assets|map(select(.name|endswith("x86_64.AppImage")))|.[].browser_download_url' | xargs curl -L -o $HOME/.local/bin/dockstation
chmod +x $HOME/.local/bin/dockstation

#todoist
#curl -L -o $HOME/.local/bin/todoist https://todoist.com/linux_app/snap
#chmod +x $HOME/.local/bin/todoist

#curl -s https://api.github.com/repos/AppImage/AppImageUpdate/releases | \
#        python3 -c \
#        "import sys, json; \
#        assets = json.load(sys.stdin)[0]['assets']; \
#        release_url = next((x for x in assets if #x['browser_download_url'].endswith('x86_64.AppImage')), None)['browser_download_url']; \
#        print(release_url)" | \
#        xargs -I % sudo curl -L % -o /usr/local/bin/appimageupdate
#sudo chmod +x /usr/local/bin/appimageupdate
#curl -s https://api.github.com/repos/jgraph/drawio-desktop/releases/latest | \
#        python3 -c \
#        "import sys, json; \
#        assets = json.load(sys.stdin)['assets']; \
#        release_url = next((x for x in assets if #x['browser_download_url'].endswith('.AppImage')), None)['browser_download_url']; \
#        print(release_url)" | \
#        xargs -I % sudo curl -L % -o /usr/local/bin/drawio
#sudo chmod +x /usr/local/bin/drawio

# INSTALL SNAPS
sudo snap install kotlin --classic
sudo snap install flutter --classic
sudo snap install dotnet-sdk --channel=lts/stable --classic
sudo snap install google-cloud-sdk --classic
sudo snap install pypy3 --classic

# INSTALL FLATPAKS
flatpak install -y \
    flathub com.jetbrains.IntelliJ-IDEA-Community \
    flathub com.google.AndroidStudio \
    flathub com.getpostman.Postman \
    flathub com.discordapp.Discord \
    flathub com.obsproject.Studio \
    flathub org.videolan.VLC \
    flathub com.slack.Slack \
    flathub com.unity.UnityHub \
    flathub com.jetbrains.PyCharm-Community \
    flathub com.bitwarden.desktop \
    flathub org.gimp.GIMP \
    flathub com.jgraph.drawio.desktop \
    flathub org.godotengine.Godot \
    flathub org.flameshot.Flameshot \
    flathub com.todoist.Todoist \
    flathub com.github.Eloston.UngoogledChromium \
    io.gitlab.librewolf-community

# INSTALL DOCKER
# docker engine
#sudo apt install -y \
#    apt-transport-https \
#    ca-certificates \
#    software-properties-common
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#sudo apt update
#sudo apt install -y \
#	docker-ce \
#	docker-ce-cli \
#	containerd.io
#sudo groupadd docker
#sudo usermod -aG docker $USER

# docker-compose
#curl -s https://api.github.com/repos/docker/compose/releases/latest | \
#        python3 -c \
#        "import sys, json; \
#        assets = json.load(sys.stdin)['assets']; \
#        release_url = next((x for x in assets if x['browser_download_url'].endswith('Linux-#x86_64')), None)['browser_download_url']; \
#        print(release_url)" | \
#        xargs -I % sudo curl -L % -o /usr/local/bin/docker-compose
#sudo chmod +x /usr/local/bin/docker-compose

# INSTALL PYTHON, CONDA AND PIP PACKAGES
#curl https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh | bash
sudo apt install -y python3-pip
pip3 install \
    awscli-local \
    localstack
# (poetry)
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3
export PATH=$PATH:$HOME/.poetry/bin

# NVM & NODE
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
cd ~
source .bashrc
nvm install --lts
nvm use --lts
npm install -g \
    firebase-tools \
    @aws-amplify/cli
    
# INSTALL RUST
cd $HOME/Downloads
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup-init.sh
chmod +x rustup-init.sh
./rustup-init.sh -y

# INSTALL DART
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt update && sudo apt install -y dart
dart --disable-analytics


# AWS CLI
cd $HOME/Downloads
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# CONFIGURE .NET SDK
sudo ln -s /snap/dotnet-sdk/current/dotnet /usr/local/bin/dotnet
sudo snap alias dotnet-sdk.dotnet dotnet
echo 'export DOTNET_CLI_TELEMETRY_OPTOUT=1' >> ~/.bashrc


# STARSHIP
# nerd font
cd $HOME/Downloads
mkdir -p $HOME/.fonts
curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq '.assets|map(select(.name == "DejaVuSansMono.zip"))|.[].browser_download_url' | xargs curl -o DejaVuSansMono.zip
# starship
curl -fsSL https://starship.rs/install.sh | bash
echo 'eval "$(starship init bash)"' >> $HOME/.bashrc
mkdir -p $HOME/.config

# FIX CLOCK
timedatectl set-local-rtc 1 --adjust-system-clock

# TIMESHIFT-APT
git clone https://github.com/wmutschl/timeshift-autosnap-apt.git $HOME/Downloads/timeshift-autosnap-apt
cd $HOME/Downloads/timeshift-autosnap-apt
sudo make install
cd ~

# CLEANUP
rm -rf $HOME/Downloads/*

