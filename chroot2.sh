#!/bin/bash
set -e

DISK="/dev/sda"

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

pacman -S grub os-prober efibootmgr nano sudo networkmanager hyprland firefox-esr --noconfirm
mkdir -p /boot/efi
mount ${DISK}1 /boot/efi

echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "share UUID=$(blkid -s UUID -o value ${DISK}3) none luks" >> /etc/crypttab
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable NetworkManager
systemctl start NetworkManager
pacman -Sy gcc 

useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd
useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd
groupadd share_users
usermod -aG share_users papa
usermod -aG share_users fiston

pacman -S virtualbox virtualbox-host-dkms
modprobe vboxdrv
modprobe vboxnetflt
modprobe vboxnetadp
usermod -aG vboxusers papa
mount ${DISK}2 /home/papa/VirtualBox VMs/

mkdir -p /mnt/share
chown root:share_users /mnt/share
chmod 770 /mnt/share
mount /dev/mapper/share_crypt /mnt/share

echo "papa ALL=(ALL) ALL" >> /etc/sudoers
