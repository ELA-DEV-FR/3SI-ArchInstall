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
VM_SIZE=$((80 * 1024))
SHARE_SIZE=$((5 * 1024))
OPTIONAL_SIZE=$((10 * 1024))

###################
# PARTITIONNEMENT #
###################
echo -e "${CYAN} Création des partitions...${RESET}"
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB ${EFI_SIZE}MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart VM ext4 ${EFI_SIZE}MiB $((EFI_SIZE + VM_SIZE))MiB
parted -s $DISK mkpart SHARE ext4 $((EFI_SIZE + VM_SIZE))MiB $((EFI_SIZE + VM_SIZE + SHARE_SIZE))MiB
parted -s $DISK mkpart OPTIONAL ext4 $((EFI_SIZE + VM_SIZE + SHARE_SIZE))MiB $((EFI_SIZE + VM_SIZE + SHARE_SIZE + OPTIONAL_SIZE))MiB
parted -s $DISK mkpart DATA ext4 $((EFI_SIZE + VM_SIZE + SHARE_SIZE + OPTIONAL_SIZE))MiB 100%
sleep 2

##################
# FORMATAGE + FS #
##################
echo -e "${CYAN} Formatage des partitions...${RESET}"
mkfs.fat -F32 ${DISK}1
mkfs.ext4 ${DISK}2
mkfs.ext4 ${DISK}4
mkfs.ext4 ${DISK}5

###############
# CHIFFREMENT #
###############
echo -e "${CYAN} Mise en place du chiffrement LUKS pour SHARE...${RESET}"
echo -n "azerty123" | cryptsetup luksFormat --type luks2 ${DISK}3
echo -n "azerty123" | cryptsetup open ${DISK}3 share_crypt
mkfs.ext4 /dev/mapper/share_crypt

###########
# MONTAGE #
###########
echo -e "${CYAN} Montage des partitions...${RESET}"
mount ${DISK}5 /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/share
mkdir -p /mnt/data
mount ${DISK}1 /mnt/boot/efi

echo -e "${GREEN} Partitionnement terminé !${RESET}"
