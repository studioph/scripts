#!/bin/bash

function parseArgs(){
    for i in "$@"; do
        case $i in
            --gen-config)
            FUNCTION=gen_config
            shift # past argument=value
            ;;
            --connect)
            FUNCTION=connect
            shift # past argument=value
            ;;
            --client-ip=*)
            CLIENT_IP="${i#*=}"
            shift # past argument=value
            ;;
            --server-ip=*)
            SERVER_IP="${i#*=}"
            shift # past argument=value
            ;;
            --public-key=*)
            PUBLIC_KEY="${i#*=}"
            shift # past argument=value
            ;;
            *)
                # unknown option
                echo "Unknown flag: $i"
            ;;
        esac
    done
}

function genConfig(){
    umask 077
    printf "[Interface]\nPrivateKey = " | sudo tee /etc/wireguard/wg0.conf > /dev/null
    wg genkey | sudo tee /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key > /dev/null
    sudo cat /etc/wireguard/private.key | sudo tee -a /etc/wireguard/wg0.conf > /dev/null
    printf "%s\n" "Address=$1" | sudo tee -a /etc/wireguard/wg0.conf > /dev/null
    sudo systemctl enable wg-quick@wg0
}

function connect(){
    printf "%s\n" "[Peer]" "PublicKey = $1" "Endpoint = $2:51820" "AllowedIPs = $3" "PersistentKeepalive = 15" | sudo tee -a /etc/wireguard/wg0.conf
    echo "Connecting to VPN..."
    sudo systemctl enable wg-quick@wg0
    sudo systemctl start wg-quick@wg0
}

parseArgs "$@"

case $FUNCTION in
    gen_config)
    genConfig $CLIENT_IP
    ;;
    connect)
    connect $PUBLIC_KEY $SERVER_IP $CLIENT_IP
    ;;
    *)
        echo "Function flag not set, exiting"
        exit
    ;;
esac