#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${GREEN}   Auto-Partitionnement & Chiffrement Arch    ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

DISK="/dev/sda"         
EFI_SIZE=512           
LVM_SIZE=$((60 * 1024)) 
PASSWD="azerty123"     
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB "${EFI_SIZE}MiB"
parted -s "$DISK" set 1 esp on


parted -s "$DISK" mkpart LVM ext4 "${EFI_SIZE}MiB" "$((EFI_SIZE + LVM_SIZE))MiB"


mkfs.fat -F32 "${DISK}1"


echo -n "$PASSWD" | cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 --batch-mode "${DISK}2"

echo -n "$PASSWD" | cryptsetup open "${DISK}2" lvm_arch
partprobe "$DISK"

echo -e "${CYAN}7) Configuration LVM dans le conteneur chiffré...${RESET}"
pvcreate /dev/mapper/lvm_arch
vgcreate vg0 /dev/mapper/lvm_arch


lvcreate -L 20G -n root vg0
lvcreate -L 10G -n home vg0
lvcreate -L 10G -n var  vg0
lvcreate -L 10G -n vm   vg0
lvcreate -L 10G -n luks vg0
lvcreate -L  5G -n share vg0



mkfs.ext4 /dev/vg0/root
mkfs.ext4 /dev/vg0/home
mkfs.ext4 /dev/vg0/var
mkfs.ext4 /dev/vg0/vm
mkfs.ext4 /dev/vg0/share
mkfs.ext4 /dev/vg0/luks


mount /dev/vg0/root /mnt

mkdir -p /mnt/boot/efi
mount "${DISK}1" /mnt/boot/efi

mkdir -p /mnt/home
mkdir -p /mnt/var
mkdir -p /mnt/share

mount /dev/vg0/home  /mnt/home
mount /dev/vg0/var   /mnt/var
mount /dev/vg0/share /mnt/share

echo -e "${GREEN}Partitionnement & chiffrement terminés !${RESET}"
