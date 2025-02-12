#!/bin/bash
set -e

DISK="/dev/sda"

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

pacman -S grub os-prober efibootmgr nano sudo  hyprland firefox virtualbox virtualbox-host-dkms --noconfirm
mkdir -p /boot/efi
mount ${DISK}1 /boot/efi

echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "UUID=$(blkid -s UUID -o value ${DISK}2) /home/papa/VirtualBox\ VMs/ ext4 defaults 0 2" >> /etc/fstab
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd
useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd

echo "papa ALL=(ALL) ALL" >> /etc/sudoers
