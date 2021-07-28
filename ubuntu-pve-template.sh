#!/bin/bash

# Written for Ubuntu Server 20.04.2 LTS

function parseArgs(){
    for i in "$@"; do
        case $i in
            --docker-user=*)
            export DOCKER_USER="${i#*=}"
            shift
            ;;
            --git-name=*)
            export GIT_NAME="${i#*=}"
            shift
            ;;
            --git-email=*)
            export GIT_EMAIL="${i#*=}"
            shift
            ;;
            --github-token=*)
            export GITHUB_TOKEN="${i#*=}"
            shift
            ;;
            --gitlab-token=*)
            export GITLAB_TOKEN="${i#*=}"
            shift
            ;;
            --nvidia)
            export NVIDIA=true
            shift
            ;;
            *)
                echo "Unknown option: $i"
            ;;
        esac
    done

    if [[ -z "$DOCKER_USER" || -z "$GIT_NAME" || -z "$GIT_EMAIL" || -z "$GITHUB_TOKEN" || -z "$GITLAB_TOKEN" ]]; then
        echo "One or more required args missing: --docker-user, --git-name, --git-email --github-token --gitlab-token"
        exit 1
    fi
}

function setupSerialConsole(){
    sudo sed -i 's/CMDLINE_LINUX_DEFAULT=""/CMDLINE_LINUX_DEFAULT="console=ttyS0,115200"/g' /etc/default/grub
    sudo update-grub
}

function setupGit(){
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global credential.helper store
    echo "https://paulhutchings:$GITHUB_TOKEN@github.com" >> "$HOME/.git-credentials"
    echo "https://wuubb:$GITLAB_TOKEN@gitlab.com" >> "$HOME/.git-credentials"
}

function packages(){
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y cockpit qemu-guest-agent fail2ban jq nfs-common cifs-utils
    sudo apt remove -y popularity-contest
}

# Configures a new systemd service to run on boot
function addStartupScript(){
    local SERVICE_NAME="$1"
    local CMD="$2"
    local DESC="$3"

    echo "\
    [Unit]
    Description=$DESC

    [Service]
    ExecStart=/bin/sh -c \"$CMD\"

    [Install]
    WantedBy=multi-user.target
    " | sudo tee "/etc/systemd/system/$SERVICE_NAME.service"

    sudo systemctl start "$SERVICE_NAME"
    sudo systemctl enable "$SERVICE_NAME"
}

function setupDocker(){
    # install docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    focal \
    stable"
    sudo apt update && sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io

    # configure the docker daemon to use namespace remapping via DOCKER_USER 
    sudo useradd -u 5000 $DOCKER_USER
    sudo sed -i '/container:/d' /etc/subuid /etc/subgid
    echo "$DOCKER_USER:5000:65536"| sudo tee -a /etc/subuid /etc/subgid
    echo {\"userns-remap\":\"$DOCKER_USER\"} | sudo tee -a /etc/docker/daemon.json
    echo DOCKER_OPTS="--config-file=/etc/docker/daemon.json" | sudo tee -a /etc/default/docker
    sudo systemctl restart docker

    # change group on /var/run/docker.sock to be $DOCKER_USER instead of docker group to allow portainer to run
    sudo chown :$DOCKER_USER /var/run/docker.sock
    addStartupScript docker-sock "chown :$DOCKER_USER /var/run/docker.sock" "Enables portainer access to docker.sock"
    
    # install docker-compose
    curl -s https://api.github.com/repos/docker/compose/releases/latest | \
        jq '.assets|map(select(.name|endswith("Linux-x86_64")))|.[].browser_download_url' | \
        xargs sudo curl -L -o /usr/bin/docker-compose
    sudo chmod +x /usr/bin/docker-compose

    # add user to docker and $DOCKER_USER groups
    sudo usermod -aG docker,$DOCKER_USER $USER
    sudo docker info
    docker-compose version 
}

function setupNvidia(){
    local NVIDIA_VERSION=460
    sudo apt install -y \
        "nvidia-headless-$NVIDIA_VERSION" \
        "nvidia-utils-$NVIDIA_VERSION" \
        "libnvidia-decode-$NVIDIA_VERSION" \
        "libnvidia-encode-$NVIDIA_VERSION"
    local DIST=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$DIST/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt update
    sudo apt install -y nvidia-docker2
    sudo systemctl restart docker
    nvidia-smi
}

parseArgs "$@"
setupSerialConsole
setupGit
packages
setupDocker
addStartupScript dev-dri "chmod -R 777 /dev/dri" "Changes permissions on /dev/dri"

if [[ -v NVIDIA ]]; then
    setupNvidia
fi
