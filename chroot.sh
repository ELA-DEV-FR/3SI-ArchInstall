#!/bin/bash

DISK="/dev/sda"
EFI_SIZE=512
VM_SIZE=$((20 * 1024))
SHARE_SIZE=$((5 * 1024))
LUKS_OPTIONAL_SIZE=$((10 * 1024))



ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

pacman -Sy grub os-prober efibootmgr nano --noconfirm
mkdir -p /boot/efi
mount /dev/sda1 /boot/efi
systemctl daemon-reload

echo "GRUB_ENABLE_CRYPTODISK=y" > /etc/default/grub
echo "optional_luks UUID=$(blkid -s UUID -o value ${DISK}4) none luks" >> /etc/crypttab
echo "luks_rest UUID=$(blkid -s UUID -o value ${DISK}5) none luks" >> /etc/crypttab
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg


useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd
useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd

pacman -Sy sudo --noconfirm
echo "papa ALL=(ALL) ALL" | tee -a /etc/sudoers