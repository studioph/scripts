#!/bin/bash

# Written for Ubuntu Server 20.04.2 LTS

for i in "$@"; do
    case $i in
        --hostname=*)
        export HOSTNAME="${i#*=}"
        shift
        ;;
        --ip1=*)
        export IP1="${i#*=}"
        shift
        ;;
        --ip10=*)
        export IP10="${i#*=}"
        shift
        ;;
        *)
            echo "Unknown option: $i"
        ;;
    esac
done

function configNetwork(){
    sudo hostnamectl set-hostname "$HOSTNAME"
    sudo sed -i "s/10.0.1.99/$IP1/g" /etc/netplan/00-installer-config.yaml
    sudo sed -i "s/10.0.10.99/$IP10/g" /etc/netplan/00-installer-config.yaml
    sudo netplan apply
}

function formatDisk(){
    echo 'type=83' | sudo sfdisk /dev/sdb
    sudo mkfs -t ext4 /dev/sdb1
    echo "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1-part1 /var/lib/docker auto defaults 0 0" | sudo tee -a /etc/fstab
    sudo mount /dev/sdb1 /var/lib/docker
    sudo systemctl restart docker
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
    sudo systemctl restart fail2ban
}

function initContainers(){
    local DOCKER_REPO="https://github.com/paulhutchings/docker-compose.git"
    cd "$HOME"
    git clone "$DOCKER_REPO"
    cd docker-compose/portainer
    sudo docker-compose up -d
}

configNetwork
formatDisk
setupFail2ban
initContainers
