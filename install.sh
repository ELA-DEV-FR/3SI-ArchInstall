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
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

########
# GRUB #
########
pacman -S grub os-prober
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

############
# HYPRLAND #
############
# DEPENDANCES :
# yay -S ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git
# pacman -S --noconfirm sudo hyprland
# pacman -S yay -y 

#########
# USERS #
#########
useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd
useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd

########
# SUDO #
########
pacman -S sudo
visudo
echo "papa ALL=(ALL) ALL" | tee -a /etc/sudoers

##########
# ENDING #
##########
echo -e "${GREEN}Installation terminée avec succès ! Redémarrage en cours...${RESET}"
exit
umount -R /mnt
reboot
