#!/bin/bash

function parseArgs(){
    
    for i in "$@"
    do
    case $i in
        --igpu)
        GVT_G=true
        IOMMU=intel
        shift # past argument=value
        ;;
        --debian)
        DEBIAN=true
        shift # past argument=value
        ;;
        --amd)
        IOMMU=amd
        shift # past argument=value
        ;;
        --intel)
        IOMMU=intel
        shift # past argument=value
        ;;
        *)
            # unknown option
            echo "Unknown option ${i%%=*}"
        ;;
    esac
    done
}

function update(){
    CODENAME=$(env -i bash -c '. /etc/os-release; echo $VERSION_CODENAME')

    # Remove sub repo and add no-sub repo
    echo "deb http://download.proxmox.com/debian/pve $CODENAME pve-no-subscription" >> /etc/apt/sources.list
    wget http://download.proxmox.com/debian/key.asc && apt-key add key.asc
    FOLDER=/etc/apt/sources.list.d
    mv $FOLDER/pve-enterprise.list $FOLDER/pve-enterprise.list.bak

    # Upgrade packages
    apt update && apt upgrade -y
    apt install -y \
        ifupdown2
}

function addPVE(){
    CODENAME=$(env -i bash -c '. /etc/os-release; echo $VERSION_CODENAME')
    echo "deb http://download.proxmox.com/debian/pve $CODENAME pve-no-subscription" >> /etc/apt/sources.list
    wget http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg -O /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg

    apt update && apt full-upgrade -y
    apt install -y proxmox-ve postfix open-iscsi ifupdown2
    apt remove -y os-prober
}

function removePopup(){
    # Remove popup
    FOLDER=/usr/share/perl5/PVE/API2
    sed -i.bak 's/NotFound/Active/g' $FOLDER/Subscription.pm
    systemctl restart pveproxy
}

function addKernelParams(){
    echo "$(paste -sd ' ' /etc/kernel/cmdline)" "$1" > /etc/kernel/cmdline
    pve-efiboot-tool refresh
    update-initramfs -u -k all
}

function setupIOMMU(){
    if [[ $IOMMU == "intel" ]]; then
        addKernelParams intel_iommu=on
    elif [[ $IOMMU == "amd" ]]; then
        addKernelParams amd_iommu=on
    else
        echo "Bad option to add kernel param: $1"
        exit -1
    fi

    printf "kvmgt\nvfio_mdev\nvfio_iommu_type1" >> /etc/modules
    update-initramfs -u -k all
}

function gvt_g(){
    # Configure GVT-g
    addKernelParams i915.enable_gvt=1
    JOB='@reboot echo "00000000-0000-0000-0000-000000000000" > /sys/devices/pci0000:00/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_8/create'
    echo "$JOB" | crontab -
}

parseArgs "$@"

if [ -z ${DEBIAN+x} ]; then
    addPVE
else
    update
fi

removePopup

setupIOMMU

if [ -z ${GVT_G+x} ]; then
    gvt_g 
fi
