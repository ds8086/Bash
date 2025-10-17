#!/bin/bash

# -------- variables --------
domain=$1
backup=/mnt/backup
folder=${backup}/${domain}
dstamp=${folder}/$(date +%Y%m%d-%H%M%S)

# -------- functions --------
# make dirs for backup
dom_folder() {
    if [ ! -d "$folder" ]; then
        mkdir -v ${folder}
    fi

    if [ ! -d "$dstamp" ]; then
        mkdir -v ${dstamp}
    fi
}

# backup domain (shutoff)
shutoff_bu() {
    echo "${domain} is powered off"

    # dump domain definition
    virsh dumpxml ${domain} > "${dstamp}/${domain}.xml"

    # determine and copy domain disks
    disks=$(egrep "*\.qcow2" "${dstamp}/${domain}.xml" | sed -rf ./backup-domain.sed)
    for d in ${disks}
    do
        cp -v $d "${dstamp}"
    done
}

# backup domain (running)
running_bu() {
    echo "${domain} is powered on"

    # dump domain definition
    virsh dumpxml ${domain} > "${dstamp}/${domain}.xml"

    # backup
    virsh backup-begin ${domain}

    # wait for backup
    job=$(virsh domjobinfo ${domain})
    while ( echo $job | egrep "Job type: Unbounded *" > /dev/null )
    do
        sleep 10s
        job=$(virsh domjobinfo ${domain})
    done

    # confirm backup completed
    job=$(virsh domjobinfo ${domain} --completed)
    if ( echo $job | egrep "Job type: Completed *" > /dev/null ) then

        # determine and move domain disks
        disks=$(egrep "*\.qcow2" "${dstamp}/${domain}.xml" | sed -rf ./backup-domain.sed)
        for d in ${disks}
        do
            mv -v $d.* $dstamp
        done

        # rename moved disks dropping the appended epoch timestamp
        moved=$(ls ${dstamp}/*.qcow2.*)
        for m in ${moved}
        do
            mv $m $(echo $m | cut -d \. -f1).$(echo $m | cut -d \. -f2)
        done
    fi
}

# determine domains' power states
virsh list --state-shutoff --name | grep -v -e '^$' > /tmp/off.txt
virsh list --state-running --name | grep -v -e '^$' > /tmp/on.txt

# backup based on domain power state
if ( grep ${domain} /tmp/off.txt > /dev/null ) then
    dom_folder
    shutoff_bu
elif ( grep ${domain} /tmp/on.txt > /dev/null ) then
    dom_folder
    running_bu
else
    echo "${domain} is not a valid domain"
    exit
fi