#!/bin/bash

##############################
# WRITTEN FOR POP!_OS 20.04.2
##############################

# Prevent Nvidia drivers from being upgraded
sudo apt-mark hold \
	xserver-xorg-video-nvidia-465 \
	libnvidia-cfg1-465 \
	libnvidia-common-465 \
	libnvidia-compute-465 \
	libnvidia-decode-465 \
	libnvidia-encode-465 \
	libnvidia-extra-465 \
	libnvidia-fbc1-465 \
	libnvidia-gl-465 \
	libnvidia-ifr1-465 \
	nvidia-compute-utils-465 \
	nvidia-dkms-465 \
	nvidia-driver-465 \
	nvidia-driver-460 \
	nvidia-kernel-common-465 \
	nvidia-kernel-source-465 \
	nvidia-settings \
	nvidia-utils-465 \
	5.11.0-7614-generic

# SYSTEM UPDATES
sudo apt update
sudo apt upgrade -y --allow-downgrades

# INSTALL PACKAGES
sudo apt update
sudo apt install -y \
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
    nvidia-container-toolkit \
    ffmpeg \
    nvidia-cuda-toolkit \
    snapd \
    gdb \
    openjdk-11-jdk \
    python3-tk \
    refind \
    jq \
    gradle \
    maven \
    golang-go \
    pypy3 \
    python3-pip \
    lm-sensors
    
# Docker Engine
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
	sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y \
	docker-ce \
	docker-ce-cli \
	containerd.io \
	tensorman

# VS Codium
wget -qO https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg | \
	gpg --dearmor | \
	sudo dd of=/etc/apt/trusted.gpg.d/vscodium.gpg 
echo 'deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs/ vscodium main' | \
	sudo tee --append /etc/apt/sources.list.d/vscodium.list 
sudo apt update
sudo apt install -y codium

sudo usermod -aG libvirt,kvm,tty,docker $USER

# REMOVE UNWANTED PACKAGES
sudo apt remove -y \
	popularity-contest \
	firefox

# INSTALL BINARIES/APPIMAGES DIRECTLY
function installBin(){
	local NAME="$1"
	local REPO="$2"
	local SELECT_NAME="$3"
	local JQ_FILTER=".assets|map(select(.name|endswith(\"$SELECT_NAME\")))|.[].browser_download_url"
	local DL_PATH=/usr/local/bin

	curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
	jq "$JQ_FILTER" | \
	xargs -I % sudo curl -L % -o "$DL_PATH/$NAME"
	
	sudo chmod +x "$DL_PATH/$NAME"
}

installBin yq mikefarah/yq linux_amd64 
installBin dockstation dockstation/dockstation x86_64.AppImage
installBin docker-compose docker/compose Linux-x86_64

#mkdir -p $HOME/.local/bin
#echo 'export PATH=$PATH:$HOME/.local/bin' >> .bashrc

# INSTALL SNAPS
sudo snap install kotlin --classic
sudo snap install flutter --classic
sudo snap install google-cloud-sdk --classic

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
    io.gitlab.librewolf-community \
    flathub rest.insomnia.Insomnia \
    flathub com.axosoft.GitKraken \
    flathub com.nextcloud.desktopclient.nextcloud

# INSTALL PYTHON, CONDA AND PIP PACKAGES
#curl https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh | bash
pip3 install \
    awscli-local \
    localstack \
    b2 \
    boto3
# poetry
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3
export PATH=$PATH:$HOME/.poetry/bin

# INSTALL NVM & NODE
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
bash --login -c "\
nvm install --lts;
nvm use --lts;
npm install -g \
    firebase-tools \
    @aws-amplify/cli;
"

# INSTALL RUST
cd $HOME/Downloads
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup-init.sh
chmod +x rustup-init.sh
./rustup-init.sh -y

# INSTALL DART
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt update
sudo apt install -y dart
dart --disable-analytics

# INSTALL AWS CLI
cd $HOME/Downloads
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# INSTALL .NET SDK
cd $HOME/Downloads
curl -O https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh 
echo 'export DOTNET_CLI_TELEMETRY_OPTOUT=true' >> ~/.bashrc

# INSTALL STARSHIP
# nerd fonts
cd $HOME/Downloads
git clone https://github.com/ryanoasis/nerd-fonts
cd nerd-fonts
chmod +x install.sh
./install.sh
# starship
curl -fsSL https://starship.rs/install.sh | bash
echo 'eval "$(starship init bash)"' >> $HOME/.bashrc
mkdir -p $HOME/.config

# FIX CLOCK
timedatectl set-local-rtc 1 --adjust-system-clock

# INSTALL TIMESHIFT-APT
#git clone https://github.com/wmutschl/timeshift-autosnap-apt.git $HOME/Downloads/timeshift-autosnap-apt
#cd $HOME/Downloads/timeshift-autosnap-apt
#sudo make install

# DISABLE USB WAKEUP
echo'
[Unit]
Description=Disables USB mouse/keyboard wakeup

[Service]
ExecStart=/bin/sh -c "echo XHC0 >> /proc/acpi/wakeup"

[Install]
WantedBy=multi-user.target
' | sudo tee /etc/systemd/system/disable-wakeup.service
sudo systemctl start disable-wakeup
sudo systemctl enable disable-wakeup

sudo sensors-detect

# CLEANUP
cd $HOME
rm -rf $HOME/Downloads/*
echo "Done"
