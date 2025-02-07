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
pacman -Syy
pacman -S reflector --noconfirm
reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacman -S cryptsetup --noconfirm 

##############
# BUILD DISK #
##############
bash disk.sh
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

######################
# CHROOT ENVIRONMENT #
######################

arch-chroot /mnt <<EOF
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

echo "optional_luks UUID=$(blkid -s UUID -o value ${DISK}4) none luks" >> /etc/crypttab
echo "luks_rest UUID=$(blkid -s UUID -o value ${DISK}5) none luks" >> /etc/crypttab

##############################
# GRUB Installation for UEFI #
##############################

mkdir -p /boot/efi
mount /dev/sda1 /boot/efi
systemctl daemon-reload
pacman -Sy grub os-prober efibootmgr 
mkdir -p /boot/efi/EFI/GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
sed -i 's/^GRUB_CMDLINE_LINUX=".*"/GRUB_CMDLINE_LINUX="cryptdevice=UUID=$(blkid -s UUID -o value ${DISK}5):luks_rest root=/dev/system/root"/' /etc/default/grub
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
