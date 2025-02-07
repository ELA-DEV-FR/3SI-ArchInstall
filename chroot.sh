#!/bin/bash
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
sed -i 's|^GRUB_CMDLINE_LINUX=".*"|GRUB_CMDLINE_LINUX="cryptdevice=UUID=$(blkid -s UUID -o value ${DISK}5):luks_rest root=/dev/system/root initrd=/boot/initramfs-linux.img"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd
useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd

# Ajout de sudo
pacman -Sy sudo --noconfirm
echo "papa ALL=(ALL) ALL" | tee -a /etc/sudoers