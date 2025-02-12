#!/bin/bash
set -e

DISK="/dev/sda"

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

pacman -S grub os-prober efibootmgr nano sudo  hyprland firefox virtualbox virtualbox-host-dkms --noconfirm
mkdir -p /boot/efi
mount ${DISK}1 /boot/efi
mkdir -p /mnt/home/papa/VirtualBox\ VMs/
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "UUID=$(blkid -s UUID -o value ${DISK}2) /home/papa/VirtualBox\ VMs/ ext4 defaults 0 2" >> /etc/fstab
echo "share UUID=$(blkid -s UUID -o value ${DISK}3) none luks" >> /etc/crypttab
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd
useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd
mkdir -p /home/papa/VirtualBox\ VMs/
chown -R papa:papa /home/papa/VirtualBox\ VMs/
chmod 777 /home/papa/VirtualBox\ VMs/
touch /etc/modules-load.d/virtualbox.conf
cat <<EOF > /etc/modules-load.d/virtualbox.conf
vboxdrv
vboxnetflt
vboxnetadp
EOF

echo "papa ALL=(ALL) ALL" >> /etc/sudoers
