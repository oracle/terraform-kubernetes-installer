#!/bin/bash -x

## Setup NVMe drives and mount at /var/lib/docker
######################################
NVMEVGNAME="NVMeVG"
NVMELVNAME="DockerVol"
NVMEDEVS=$(lsblk -I259 -pn -oNAME -d)
if [[ ! -z "$${NVMEDEVS}" ]]; then
    lvs $${NVMEVGNAME}/$${NVMELVNAME} --noheadings --logonly 1>/dev/null
    if [ $$? -ne 0 ]; then
	pvcreate $${NVMEDEVS}
	vgcreate $${NVMEVGNAME} $${NVMEDEVS}
	lvcreate --extents 100%FREE --name $${NVMELVNAME} $${NVMEVGNAME} $${NVMEDEVS}
	mkfs -t xfs /dev/$${NVMEVGNAME}/$${NVMELVNAME}
	mkdir -p /var/lib/docker
	mount -t xfs /dev/$${NVMEVGNAME}/$${NVMELVNAME} /var/lib/docker
	echo "/dev/$${NVMEVGNAME}/$${NVMELVNAME} /var/lib/docker xfs rw,relatime,seclabel,attr2,inode64,noquota 0 2" >> /etc/fstab
    fi
fi

## Login iSCSI volume mount and create filesystem
######################################
iqn=$(iscsiadm --mode discoverydb --type sendtargets --portal 169.254.2.2:3260 --discover| cut -f2 -d" ")

if [ -n "$${iqn}" ]; then
    echo "iSCSI Login $${iqn}"
    iscsiadm -m node -o new -T $${iqn} -p 169.254.2.2:3260
    iscsiadm -m node -o update -T $${iqn} -n node.startup -v automatic
    iscsiadm -m node -T $${iqn} -p 169.254.2.2:3260 -l
    # Wait for device to apear...
    until [[ -e "/dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1" ]]; do sleep 1 && echo -n "."; done
    # If the volume has been created and formatted before but it's just a new instance this may fail
    # but if so ignore and carry on.
    mkfs -t xfs "/dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1";
    echo "$$(readlink -f /dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1) ${worker_iscsi_volume_mount} xfs defaults,noatime,_netdev 0 2" >> /etc/fstab
    mkdir -p ${worker_iscsi_volume_mount}
    mount -t xfs "/dev/disk/by-path/ip-169.254.2.2:3260-iscsi-$${iqn}-lun-1" ${worker_iscsi_volume_mount}
fi

######################################
echo "Finished running setup.sh"
