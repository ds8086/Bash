#!/bin/bash

# variables
domain=$1
backup=/mnt/backup
folder=${backup}/${domain}
dstamp=${folder}/$(date +%Y%m%d-%H%M%S)

# virtual machines
virsh list --state-shutoff --name | grep -v -e '^$' > /tmp/off.txt
virsh list --state-running --name | grep -v -e '^$' > /tmp/on.txt

# determine if vm is running and power off if so
if ( grep ${domain} /tmp/off.txt > /dev/null ) then
    echo "${domain} is powered off"
    boot=0
elif ( grep ${domain} /tmp/on.txt > /dev/null ) then
    echo "${domain} is powered on, powering off"
    virsh shutdown ${domain}
    boot=1
    echo "sleeping 90s to allow power off"
    sleep 90s
else
    echo "${domain} is not a valid VM"
    exit
fi

# create backup folder for vm
if [ ! -d "$folder" ]; then
    mkdir -v ${folder}
fi

# create datestamp folder for backup
if [ ! -d "$dstamp" ]; then
    mkdir -v ${dstamp}
fi

# dump vm definition
virsh dumpxml ${domain} > "${dstamp}/${domain}.xml"

# determine and copy vm disks
disks=$(egrep "*\.qcow2" "${dstamp}/${domain}.xml" | sed -rf ./backup-domain.sed)
for d in ${disks}
do
    cp -v $d "${dstamp}"
done

# boot vm if previously running
if [ ${boot} == 1 ]; then
    echo "starting ${domain}"
    virsh start ${domain}
else
    echo "${domain} was not running and will remain powered off"
fi