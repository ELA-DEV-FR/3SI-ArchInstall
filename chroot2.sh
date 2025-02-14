#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

DISK="/dev/sda"
echo -e "${CYAN}Configuration du système en chroot...${RESET}"

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

pacman -S --noconfirm grub
pacman -S --noconfirm os-prober
pacman -S --noconfirm efibootmgr
pacman -S --noconfirm nano
pacman -S --noconfirm sudo
pacman -S --noconfirm NetworkManager
pacman -S --noconfirm firefox 
pacman -S --noconfirm virtualbox 
pacman -S --noconfirm virtualbox-host-dkms 
pacman -S --noconfirm cryptsetup 
pacman -S --noconfirm lvm2
pacman -S --noconfirm i3 
pacman -S --noconfirm i3status 
pacman -S --noconfirm i3lock 
pacman -S --noconfirm dmenu 
pacman -S --noconfirm feh 
pacman -S --noconfirm xorg-xinit 
pacman -S --noconfirm xorg-server
pacman -S --noconfirm xorg-xrandr 
pacman -S --noconfirm xorg-xrdb 
pacman -S --noconfirm ttf-dejavu 
pacman -S --noconfirm compton



useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd

useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd

mkdir -p /var/lib/virtualbox

vgchange -ay

mount /dev/vg0/vm /var/lib/virtualbox

mkdir -p /boot/efi
mount "${DISK}1" /boot/efi

CRYPT_UUID=$(blkid -s UUID -o value "${DISK}2")

echo "lvm_crypt UUID=${CRYPT_UUID} none luks" > /etc/crypttab
echo "HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)" >> /etc/mkinitcpio.conf

cat <<EOF > /etc/default/grub
GRUB_ENABLE_CRYPTODISK=y
GRUB_PRELOAD_MODULES="luks2 part_gpt cryptodisk gcry_rijndael gcry_sha512 lvm ext2"
GRUB_CMDLINE_LINUX="cryptdevice=UUID=${CRYPT_UUID}:lvm_crypt root=/dev/mapper/vg0-root"
EOF

vgchange -ay

mkinitcpio -P

grub-install --target=x86_64-efi --efi-directory=/boot/efi  --modules="luks2 part_gpt cryptodisk gcry_rijndael gcry_sha512 lvm ext2" --recheck

grub-mkconfig -o /boot/grub/grub.cfg

mkinitcpio -P

systemctl enable NetworkManager

cat <<EOF > /etc/modules-load.d/virtualbox.conf
vboxdrv
vboxnetflt
vboxnetadp
dm-crypt
EOF

echo "papa ALL=(ALL) ALL" >> /etc/sudoers

echo -e "${GREEN}Configuration chroot terminée avec succès !${RESET}"
