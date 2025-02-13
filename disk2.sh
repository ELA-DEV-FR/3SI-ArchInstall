#!/bin/bash

# Définition des couleurs
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${GREEN}      Auto-Partitionnement Arch Linux         ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

DISK="/dev/sda"
EFI_SIZE=512
LVM_SIZE=$((60 * 1024))

###################
# PARTITIONNEMENT #
###################
echo -e "${CYAN} Création des partitions...${RESET}"
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB ${EFI_SIZE}MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart LVM ext4 ${EFI_SIZE}MiB $((EFI_SIZE + LVM_SIZE))MiB
sleep 2

##################
# FORMATAGE + FS #
##################
echo -e "${CYAN} Formatage des partitions...${RESET}"
mkfs.fat -F32 ${DISK}1

###############
# CHIFFREMENT #
###############
echo -e "${CYAN} Mise en place du chiffrement LUKS pour le volume physique...${RESET}"
echo -n "azerty123" | cryptsetup luksFormat --type luks2 --batch-mode ${DISK}2
echo -n "azerty123" | cryptsetup open ${DISK}2 lvm_crypt
partprobe ${DISK}

###############
# CONFIG LVM #
###############
echo -e "${CYAN} Configuration de LVM...${RESET}"
pvcreate /dev/mapper/lvm_crypt
vgcreate vg0 /dev/mapper/lvm_crypt
lvcreate -L 20G -n root vg0
lvcreate -L 10G -n home vg0
lvcreate -L 10G -n var vg0
lvcreate -L 10G -n vm vg0
lvcreate -L 5G -n share vg0

###########
# FORMATAGE #
###########
mkfs.ext4 /dev/vg0/root
mkfs.ext4 /dev/vg0/home
mkfs.ext4 /dev/vg0/var
mkfs.ext4 /dev/vg0/vm
mkfs.ext4 /dev/vg0/share

###########
# MONTAGE #
###########
echo -e "${CYAN} Montage des partitions...${RESET}"
mount /dev/vg0/root /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mkdir -p /mnt/var
mkdir -p /mnt/vm
mkdir -p /mnt/share
mount ${DISK}1 /mnt/boot/efi
mount /dev/vg0/home /mnt/home
mount /dev/vg0/var /mnt/var
mount /dev/vg0/vm /mnt/vm
mount /dev/vg0/share /mnt/share

echo -e "${GREEN} Partitionnement terminé !${RESET}"
