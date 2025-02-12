#!/bin/bash
set -e

DISK="/dev/sda"

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

pacman -S grub os-prober efibootmgr nano sudo networkmanager hyprland firefox virtualbox virtualbox-host-dkms --noconfirm
mkdir -p /boot/efi
mount ${DISK}1 /boot/efi

# Ajout des entrées dans /etc/crypttab
cat <<EOF > /etc/crypttab
lvm_crypt UUID=$(blkid -s UUID -o value ${DISK}2) none luks
EOF

# Ajout des entrées dans /etc/fstab
cat <<EOF > /etc/fstab
/dev/mapper/vg0-root / ext4 defaults 0 1
/dev/mapper/vg0-home /home ext4 defaults 0 2
/dev/mapper/vg0-var /var ext4 defaults 0 2
/dev/mapper/vg0-vm /vm ext4 defaults 0 2
/dev/mapper/vg0-share /share ext4 defaults 0 2
UUID=$(blkid -s UUID -o value ${DISK}1) /boot/efi vfat defaults 0 2
EOF

echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
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

# Ajout des modules VirtualBox
cat <<EOF > /etc/modules-load.d/virtualbox.conf
vboxdrv
vboxnetflt
vboxnetadp
EOF

echo "papa ALL=(ALL) ALL" >> /etc/sudoers

echo -e "${GREEN} Installation terminée !${RESET}"
