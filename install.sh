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

fdisk "/dev/sda"
echo n 
echo p 
echo 1
echo
echo +512M # partition boot 
echo n
echo p 
echo 2 
echo 
echo +10G # partition chiffrée 
echo n
echo p
echo 3 
echo 
echo +10G # partition /home
echo n 
echo p 
echo 4
echo 
echo +2G # partition /tmp 
echo n 
echo p 
echo 5 
echo  
echo +10G # partition /var notamment pour virtualbox avec mountpoint specifique 
echo n
echo p 
echo 6 
echo 
echo +5G # partition /share 
echo n 
echo p 
echo 7 
echo 
echo +5G # pour le / 

echo w

echo -n "azerty123" | cryptsetup luksFormat --type luks2 $ROOT_PARTITION



mkfs.ext4 "/boot"
mkfs.ext4 "/"
mkfs.ext4 "/share"
mkfs.ext4 "/tmp"
mkfs.ext4 "/home"


mount /dev/sda6 /mnt

############
# HYPRLAND #
############
# DEPENDANCES :
yay -S ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite libxrender pixman wayland-protocols cairo pango libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus hyprlang-git hyprcursor-git hyprwayland-scanner-git xcb-util-errors hyprutils-git glaze hyprgraphics-git
pacman -S --noconfirm sudo hyprland
pacman -S yay -y 

#########
# USERS #
#########
echo "père:azerty123" | chpasswd
useradd -m "fiston:azerty123" | chpasswd 
