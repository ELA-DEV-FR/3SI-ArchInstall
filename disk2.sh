#!/bin/bash

# --- Couleurs (optionnel) ---
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${GREEN}   Auto-Partitionnement & Chiffrement Arch    ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

DISK="/dev/sda"         # Adapter si besoin
EFI_SIZE=512            # Taille de la partition EFI (en Mio)
LVM_SIZE=$((60 * 1024)) # Taille de la partition LVM (60 Gio)
PASSWD="azerty123"      # Mot de passe LUKS (exemple peu sécurisé !)

echo -e "${CYAN}1) Création du label GPT...${RESET}"
parted -s "$DISK" mklabel gpt

echo -e "${CYAN}2) Création de la partition EFI...${RESET}"
parted -s "$DISK" mkpart ESP fat32 1MiB "${EFI_SIZE}MiB"
parted -s "$DISK" set 1 esp on

echo -e "${CYAN}3) Création de la partition LVM (chiffrée)...${RESET}"
parted -s "$DISK" mkpart LVM ext4 "${EFI_SIZE}MiB" "$((EFI_SIZE + LVM_SIZE))MiB"

echo -e "${CYAN}4) Formatage de la partition EFI en FAT32...${RESET}"
mkfs.fat -F32 "${DISK}1"

echo -e "${CYAN}5) Configuration LUKS sur ${DISK}2...${RESET}"
# Pour de meilleures pratiques : --type luks2 --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 2000 --pbkdf argon2id
# Ici on reste proche de ton script existant :
echo -n "$PASSWD" | cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 --batch-mode "${DISK}2"

echo -e "${CYAN}6) Ouverture du conteneur chiffré (lvm_crypt)...${RESET}"
echo -n "$PASSWD" | cryptsetup open "${DISK}2" lvm_crypt
partprobe "$DISK"

echo -e "${CYAN}7) Configuration LVM dans le conteneur chiffré...${RESET}"
pvcreate /dev/mapper/lvm_crypt
vgcreate vg0 /dev/mapper/lvm_crypt

# Exemple de volumes logiques
lvcreate -L 20G -n root vg0
lvcreate -L 10G -n home vg0
lvcreate -L 10G -n var  vg0
lvcreate -L 10G -n vm   vg0
lvcreate -L  5G -n share vg0

echo -e "${CYAN}8) Formatage des volumes logiques...${RESET}"
mkfs.ext4 /dev/vg0/root
mkfs.ext4 /dev/vg0/home
mkfs.ext4 /dev/vg0/var
mkfs.ext4 /dev/vg0/vm
mkfs.ext4 /dev/vg0/share

echo -e "${CYAN}9) Montage des partitions...${RESET}"
mount /dev/vg0/root /mnt

mkdir -p /mnt/boot/efi
mount "${DISK}1" /mnt/boot/efi

mkdir -p /mnt/home
mkdir -p /mnt/var
mkdir -p /mnt/vm
mkdir -p /mnt/share

mount /dev/vg0/home  /mnt/home
mount /dev/vg0/var   /mnt/var
mount /dev/vg0/vm    /mnt/vm
mount /dev/vg0/share /mnt/share

echo -e "${GREEN}Partitionnement & chiffrement terminés !${RESET}"
