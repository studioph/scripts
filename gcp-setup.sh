#!/bin/bash

# Written for Ubuntu 20.04 LTS Minimal Image on Google Compute Engine

function parseArgs(){
    for i in "$@"; do
        case $i in
#             --key-file=*)
#             KEYFILE="${i#*=}"
#             shift # past argument=value
#             ;;
#             --bucket=*)
#             export BUCKET="${i#*=}"
#             shift # past argument=value
#             ;;
#             --domain-name=*)
#             export DOMAIN_NAME="${i#*=}"
#             shift # past argument=value
#             ;;
#             --client-name=*)
#             export CLIENT_NAME="${i#*=}"
#             shift # past argument=value
#             ;;
            --docker-user=*)
            export DOCKER_USER="${i#*=}"
            shift # past argument=value
            ;;
            --pihole-pwd=*)
            export PIHOLE_PWD="${i#*=}"
            shift # past argument=value
            ;;
            *)
                # unknown option
            ;;
        esac
    done
}

# function activate(){
#     activate service account
#     echo 'Activating serevice account...'
#     gcloud auth activate-service-account --key-file=$KEYFILE
#     sudo rm $KEYFILE
# }

function makeSwapfile(){
    echo 'Creating swap file...'
    sudo dd if=/dev/zero of=/swapfile bs=1024 count=1048576
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
    free -h
}

function installPackages(){
    # install updates
    sudo apt update && sudo apt upgrade -y

    # install packages
    sudo apt install -y \
    nano \
    iputils-ping \
    apt-utils \
    dialog \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    wireguard 
}

# function init(){
#     create container directory
#     export CONTAINER_DIR=~/container
#     mkdir -p $CONTAINER_DIR
#     echo "export CONTAINER_DIR=~/container" >> ~/.bashrc
# 
#     create alias for wan ip address
#     echo alias wanip=\'curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H \"Metadata-Flavor: Google\"\' >> ~/.bash_aliases
#     source .bashrc
#     echo $(wanip)
# 
#     if [[ -n $DOMAIN_NAME ]]; then
#         sudo hostnamectl set-hostname $DOMAIN_NAME
#         echo 127.0.0.1 $DOMAIN_NAME | sudo tee -a /etc/hosts > /dev/null
#     fi
# 
#     configure git
#     GIT_CONFIG=git@$(if [[ -n $DOMAIN_NAME ]]; then echo $DOMAIN_NAME; else wanip; fi)
#     git config --global user.email $GIT_CONFIG && git config --global user.name $GIT_CONFIG
# }

# function mountBucket(){
#     install gcsfuse to mount storage buckets
#     export GCSFUSE_REPO=gcsfuse-focal
#     echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
#     curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
#     sudo apt update && sudo apt install -y gcsfuse
# 
#     mount bucket
#     export BUCKET_PATH=~/bucket/$BUCKET/
#     mkdir -p $BUCKET_PATH
#     gcsfuse $BUCKET $BUCKET_PATH
# 
#     add to fstab to mount automatically
#     echo $BUCKET $BUCKET_PATH gcsfuse rw,systemd.requires=network-online.target,user | sudo tee -a /etc/fstab > /dev/null
# }

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

    # install docker-compose
    curl -s https://api.github.com/repos/docker/compose/releases/latest | \
        python3 -c \
        "import sys, json; \
        assets = json.load(sys.stdin)['assets']; \
        release_url = next((x for x in assets if x['browser_download_url'].endswith('Linux-x86_64')), None)['browser_download_url']; \
        print(release_url)" | \
        xargs -I % sudo curl -L % -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # add user to docker and $DOCKER_USER groups
    sudo usermod -aG docker,$DOCKER_USER $USER
    sudo docker info
    docker-compose version 
    
}

# function portainer(){
#     curl -o docker-compose.yml https://raw.githubusercontent.com/paulhutchings/docker-compose/master/portainer/docker-compose.yml 
#     sudo docker-compose up -d
#     rm docker-compose.yml
# }

# function openvpn(){
#     deploy openvpn
#     cd $CONTAINER_DIR
#     gcloud source repos clone openvpn
#     cd openvpn
# 
#     create data dir if doesn't exist
#     if [[ ! -d ovpn-data ]]; then 
#         mkdir ovpn-data
#     fi
#     sudo chown -R :$DOCKER_USER ovpn-data
# 
#     create configuration if doesn't exist
#     if [[ ! -f ovpn-data/openvpn.conf ]]; then
#         sudo docker-compose run --rm openvpn ovpn_genconfig -r 10.0.1.0/24 -n 10.0.1.1 -u udp://$(if [[ -n $DOMAIN_NAME ]]; then echo $DOMAIN_NAME; else wanip; fi)
#         sudo docker-compose run --rm openvpn ovpn_initpki
#     fi
# 
#     optionally generate client file and save into storage bucket for retrieval
#     if [[ -n $CLIENT_NAME ]]; then
#         make directory tree in bucket if doesn't exist
#         if [[ ! -d $BUCKET_PATH/openvpn ]]; then
#             mkdir -p $BUCKET_PATH/openvpn/clients
#         fi
#         docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME nopass
#         docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > $BUCKET_PATH/openvpn/clients/$CLIENT_NAME.ovpn
#     fi
# 
#     sudo docker-compose up -d
# 
#     sudo ln -s $CONTAINER_DIR/openvpn/ovpn-sync.sh /etc/cron.daily/ovpn-sync
#     sudo chmod +x ovpn-sync.sh
# }

function pihole(){
    # allow pihole container to access port 53
    sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
    sudo sh -c 'rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf'
    sudo systemctl disable systemd-resolved
    sudo systemctl stop systemd-resolved

    # deploy pihole
    curl -o docker-compose.yml https://raw.githubusercontent.com/paulhutchings/docker-compose/master/pihole/docker-compose.yml
    sudo docker-compose up -d
    echo "Sleeping for 60s while pihole container starts..."
    sleep 60s
    sudo docker exec pihole pihole status
    sudo docker exec pihole pihole -a -p $PIHOLE_PWD
    rm docker-compose.yml

    # change DNS server to Pihole
    echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
}

# function deployContainers(){
#     echo 'Deploying containers...'
#     portainer
#     pihole
# }

function wireguard(){
    # enable ipv4 forwarding
    sudo sysctl -w net.ipv4.ip_forward=1
    echo net.ipv4.ip_forward=1 | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p /etc/sysctl.conf
    sudo /etc/init.d/procps restart

    umask 077
    sudo mkdir /etc/wireguard/keys
    printf "[Interface]\nPrivateKey = " | sudo tee /etc/wireguard/wg0.conf > /dev/null
    wg genkey | sudo tee /etc/wireguard/keys/private.key | wg pubkey | sudo tee /etc/wireguard/keys/public.key > /dev/null
    sudo cat /etc/wireguard/keys/private.key | sudo tee -a /etc/wireguard/wg0.conf > /dev/null
    printf "%s\n" "ListenPort = 820" "Address = 10.0.2.1/24" "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE; iptables -A FORWARD -o %i -j ACCEPT" "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE; iptables -D FORWARD -o %i -j ACCEPT" | sudo tee -a /etc/wireguard/wg0.conf > /dev/null
    sudo systemctl enable wg-quick@wg0
    sudo systemctl start wg-quick@wg0
    sudo wg
}


# get required information
parseArgs "$@"

# configure SDK
# activate

# add swapfile
makeSwapfile

# install packages and software
installPackages

# get external ip address
# init

# mount cloud storage bucket
# mountBucket

# install docker and docker-compose
setupDocker

# deploy containers
# deployContainers
pihole


# setup wireguard
wireguard
