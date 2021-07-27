#!/bin/bash

# Written for Ubuntu Server 20.04.2 LTS

function parseArgs(){
    for i in "$@"; do
        case $i in
            --docker-user=*)
            export DOCKER_USER="${i#*=}"
            shift # past argument=value
            ;;
            --git-name=*)
            export GIT_NAME="${i#*=}"
            shift # past argument=value
            ;;
            --git-email=*)
            export GIT_EMAIL="${i#*=}"
            shift # past argument=value
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

    if [[ -z "$DOCKER_USER" || -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
        echo "One or more required args missing: --docker-user, --git-name, --git-email"
        exit 1
    fi
}

function setupGit(){
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global credential.helper store
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
    ExecStart=/bin/sh -c $CMD

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

function setupFail2ban(){
    local F2B_DIR="/etc/fail2ban"
    local F2B_REPO="https://gitlab.com/wuubb/fail2ban"
    cd "$HOME"
    git clone "$F2B_REPO"
    cd fail2ban
    sudo ln -s "$PWD/jail.local" "$F2B_DIR/jail.local"
    cd filter.d
    for i in *; do sudo ln -s "$PWD/$i" "$F2B_DIR/filter.d/$i"; done
    cd ../jail.d
    for i in *; do sudo ln -s "$PWD/$i" "$F2B_DIR/jail.d/$i"; done
}

function initContainers(){
    local DOCKER_REPO="https://github.com/paulhutchings/docker-compose.git"
    cd "$HOME"
    git clone "$DOCKER_REPO"
    cd docker-compose/portainer
    sudo docker-compose up -d
}

function setupNvidia(){
    local NVIDIA_VERSION=460
    sudo apt install -y \
        "nvidia-headless-$NVIDIA_VERSION-server" \
        "nvidia-utils-$NVIDIA_VERSION" \
        "libnvidia-decode-$NVIDIA_VERSION" \
        "libnvidia-encode-$NVIDIA_VERSION"
    nvidia-smi
}

parseArgs "$@"
packages
setupDocker
setupGit
setupFail2ban
addStartupScript dev-dri "chmod -R 777 /dev/dri" "Changes permissions on /dev/dri"

if [[ -v NVIDIA ]]; then
    setupNvidia
fi

initContainers
