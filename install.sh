#!/bin/bash

###########
# CREDITS #
###########
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

DISK="/dev/sda"
EFI_SIZE=512
VM_SIZE=$((20 * 1024))
SHARE_SIZE=$((5 * 1024))
LUKS_OPTIONAL_SIZE=$((10 * 1024))

echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${GREEN}                Arch AUTO install                 ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"
echo -e "${BOLD}${WHITE}                   Made By                     ${RESET}"
echo -e "${GREEN} • L.Emeric 3SI                                ${RESET}"
echo -e "${GREEN} • M.Julien 3SI                                ${RESET}"
echo -e "${CYAN}-----------------------------------------------${RESET}"

############
# KEYBOARD #
############
loadkeys fr
pacman -Syu
pacman -S reflector --noconfirm
reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -S cryptsetup --noconfirm

##############
# BUILD DISK #
##############
bash disk2.sh
mkdir -p /mnt/boot/efi
mount ${DISK}1 /mnt/boot/efi
pacstrap /mnt base linux linux-firmware lvm2 nano 
genfstab -U /mnt >> /mnt/etc/fstab

######################
# CHROOT ENVIRONMENT #
######################
cp chroot2.sh /mnt/root/chroot.sh
chmod +x /mnt/root/chroot.sh
arch-chroot /mnt /root/chroot.sh
mkinitcpio -P

##########
# ENDING #
##########
echo -e "${GREEN}Installation terminée avec succès ! Redémarrage en cours...${RESET}"
umount -R /mnt
reboot
