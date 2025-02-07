#!/bin/bash

# Définition des couleurs
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${GREEN}      Auto-Partitionnement Arch Linux         ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

# Variables
DISK="/dev/sda"
EFI_SIZE=512
VM_SIZE=$((20 * 1024))
SHARE_SIZE=$((5 * 1024))
LUKS_OPTIONAL_SIZE=$((10 * 1024))

###################
# PARTITIONNEMENT # 
###################
echo -e "${CYAN} Création des partitions...${RESET}"
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB ${EFI_SIZE}MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart VM ext4 ${EFI_SIZE}MiB $((EFI_SIZE + VM_SIZE))MiB
parted -s $DISK mkpart SHARE ext4 $((EFI_SIZE + VM_SIZE))MiB $((EFI_SIZE + VM_SIZE + SHARE_SIZE))MiB
parted -s $DISK mkpart OPTIONAL_LUKS ext4 $((EFI_SIZE + VM_SIZE + SHARE_SIZE))MiB $((EFI_SIZE + VM_SIZE + SHARE_SIZE + LUKS_OPTIONAL_SIZE))MiB
parted -s $DISK mkpart LUKS_REST ext4 $((EFI_SIZE + VM_SIZE + SHARE_SIZE + LUKS_OPTIONAL_SIZE))MiB 100%
sleep 2

##################
# FORMATAGE + FS #
##################
echo -e "${CYAN} Formatage des partitions...${RESET}"
mkfs.fat -F32 ${DISK}1
mkfs.ext4 ${DISK}2
mkfs.ext4 ${DISK}3

###############
# CHIFFREMENT # 
###############
echo -e "${CYAN} Mise en place du chiffrement LUKS...${RESET}"
echo -n "azerty123" | cryptsetup luksFormat --type luks2 ${DISK}4
echo -n "azerty123" | cryptsetup luksFormat --type luks2 ${DISK}5

#################
# DECHIFFREMENT # 
#################
echo -e "${CYAN} Déverrouillage des volumes chiffrés...${RESET}"
echo -n "azerty123" | cryptsetup open ${DISK}4 optional_luks
pvcreate /dev/mapper/optional_luks
vgcreate secure /dev/mapper/optional_luks
lvcreate -l 100%FREE secure -n system

mkfs.ext4 /dev/secure/system
mkfs.ext4 /dev/mapper/luks_rest

echo -n "azerty123" | cryptsetup open ${DISK}5 luks_rest

##################
# FORMATAGE + FS #
##################
mount /dev/secure/system /mnt
mkdir -p /mnt/home
mount /dev/mapper/luks_rest /mnt/home
mkfs.ext4 /dev/mapper/luks_rest

###########
# MONTAGE #
###########
echo -e "${CYAN} Montage des partitions...${RESET}"
mount /dev/mapper/optionnal_luks /mnt
mount -o subvol=@home /dev/mapper/optionnal_luks /mnt/home
echo -e "${GREEN} Partitionnement terminé !${RESET}"
