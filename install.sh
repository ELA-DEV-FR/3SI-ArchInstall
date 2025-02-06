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

mkfs.fat -F32 /dev/sda1
pacman -Syy
pacman -S reflector -y 
reflector -c "US" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist
pacman -S cryptsetup -y 

##############
# BUILD DISK #
##############
bash disk.sh
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

######################
# CHROOT ENVIRONMENT #
######################
arch-chroot /mnt <<EOF
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

##############################
# GRUB Installation for UEFI #
##############################

mount /dev/sda /boot/efi
pacman -S grub os-prober --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

############
# USERS #
############
useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd
useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd

########
# SUDO #
########
pacman -S sudo --noconfirm
echo "papa ALL=(ALL) ALL" | tee -a /etc/sudoers

# pacman -S yay ninja gcc cmake meson libxcb ...
EOF

##########
# ENDING #
##########
echo -e "${GREEN}Installation terminée avec succès ! Redémarrage en cours...${RESET}"
#umount -R /mnt
#reboot
