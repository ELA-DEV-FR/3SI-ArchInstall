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
pacman -Syy
pacman -S reflector --noconfirm
reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -S cryptsetup --noconfirm 
mkfs.fat -F32 /dev/sda1
##############
# BUILD DISK #
##############
bash disk.sh
pacstrap /mnt/arch base linux linux-firmware
genfstab -U /mnt/arch >> /mnt/arch/etc/fstab
######################
# CHROOT ENVIRONMENT #
######################
arch-chroot /mnt/arch <<EOF
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname
##############################
# GRUB Installation for UEFI #
##############################

mkdir /boot/efi
mount /dev/sda1 /boot/efi
systemctl daemon-reload
pacman -Sy grub os-prober efibootmgr 
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
pacman -Sy sudo 
echo "papa ALL=(ALL) ALL" | tee -a /etc/sudoers

#pacman -S ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus
#yay -S hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git

#pacman -Sy hyprland
EOF

##########
# ENDING #
##########
echo -e "${GREEN}Installation terminée avec succès ! Redémarrage en cours...${RESET}"
umount -R /mnt
reboot
