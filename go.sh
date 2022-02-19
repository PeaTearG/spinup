#!/bin/bash
VBOXDIR="/Applications/VirtualBox.app/Contents/MacOS/"


AGVERSION=$(echo "$1" | sed 's/\.//g')
VMNAME="Appgate$AGVERSION"
VMDIR=~/VirtualBoxVMs/$VMNAME

echo "Creating VM directory on host"
$VBOXDIR/VBoxManage createvm --name $VMNAME --ostype Ubuntu_64 --register --basefolder ~/VirtualBoxVMs

ISODIR=~/VirtualBoxVMs/agisos
TOPVERSION=$(echo "$1" | sed 's/\..$//g')

mkdir -p $ISODIR
echo "Checking for $1 ISO in $ISODIR"

#modifying the URL for the version since >= 5.4 APPGATE has a lowercase "g" aka Appgate versus AppGate in prior versions
if [[ "$1" =~ 5\.[1-3]\.\d* ]]
then
    URL="https://bin.appgate-sdp.com/$TOPVERSION/appliance/AppGate-SDP-$1.iso"
else
    URL="https://bin.appgate-sdp.com/$TOPVERSION/appliance/Appgate-SDP-$1.iso"
fi


if [ -e $ISODIR/$1.iso ]
then
    echo "ISO exists"
else
    echo "Downloading..."
    echo $URL
    curl -u "${AGDLUN}:${AGDLPW}" $URL --output $ISODIR/$1.iso
fi


$VBOXDIR/VBoxManage modifyvm $VMNAME --ioapic on
$VBOXDIR/VBoxManage modifyvm $VMNAME --memory 2048 --vram 16
$VBOXDIR/VBoxManage modifyvm $VMNAME --nic1 nat
$VBOXDIR/VBoxManage modifyvm $VMNAME --graphicscontroller vmsvga
$VBOXDIR/VBoxManage modifyvm $VMNAME --rtcuseutc on
$VBOXDIR/VBoxManage modifyvm $VMNAME --natpf1 "adminportal,tcp,,$AGVERSION,,8443"
$VBOXDIR/VBoxManage createhd --filename $VMDIR/$VMNAME_DISK.vdi --size 30000 --format VDI
$VBOXDIR/VBoxManage storagectl $VMNAME --name "SATA" --add sata --controller IntelAhci
$VBOXDIR/VBoxManage storageattach $VMNAME --storagectl "SATA" --port 0 --device 0 --type hdd --medium  $VMDIR/$VMNAME_DISK.vdi
$VBOXDIR/VBoxManage storagectl $VMNAME --name "IDE Controller" --add ide --controller PIIX4
$VBOXDIR/VBoxManage storageattach $VMNAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium $ISODIR/$1.iso
#$VBOXDIR/VBoxManage modifyvm $VMNAME --boot1 disk --boot2 dvd --boot3 none --boot4 none
$VBOXDIR/VBoxManage startvm $VMNAME --type headless
