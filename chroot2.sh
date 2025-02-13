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

pacman -S --noconfirm grub os-prober efibootmgr nano sudo networkmanager \
  hyprland firefox virtualbox virtualbox-host-dkms cryptsetup lvm2
pacman -S --noconfirm i3 i3status i3lock dmenu feh xorg-xinit xorg-server \
  xorg-xrandr xorg-xrdb ttf-dejavu compton


useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd

useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd

mkdir -p "/home/papa/VirtualBox VMs/"
chown -R papa:papa "/home/papa/VirtualBox VMs/"
chmod 777 "/home/papa/VirtualBox VMs/"

mount /dev/vg0/vm    /home/papa/VirtualBox VMs/

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
