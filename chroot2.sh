#!/bin/bash

DISK="/dev/sda"

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

pacman -S grub os-prober efibootmgr nano sudo networkmanager hyprland firefox virtualbox virtualbox-host-dkms cryptsetup lvm2 --noconfirm
mkdir -p /boot/efi
mount ${DISK}1 /boot/efi

echo -e "${CYAN}Vérification de l'UUID de la partition chiffrée...${RESET}"
CRYPT_UUID=$(blkid -s UUID -o value ${DISK}2)

cat <<EOF > /etc/crypttab
lvm_crypt UUID=${CRYPT_UUID} none luks
EOF

cat <<EOF > /etc/fstab
/dev/mapper/vg0-root / ext4 defaults 0 1
/dev/mapper/vg0-home /home ext4 defaults 0 2
/dev/mapper/vg0-var /var ext4 defaults 0 2
/dev/mapper/vg0-vm /vm ext4 defaults 0 2
/dev/mapper/vg0-share /share ext4 defaults 0 2
UUID=$(blkid -s UUID -o value ${DISK}1) /boot/efi vfat defaults 0 2
EOF

sed -i 's/^HOOKS=(.*)$/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

systemctl daemon-reload
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub

sed -i "s|^GRUB_CMDLINE_LINUX=\"\(.*\)\"|GRUB_CMDLINE_LINUX=\"\1 cryptdevice=UUID=${CRYPT_UUID}:lvm_crypt\"|" /etc/default/grub

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


cat <<EOF > /etc/modules-load.d/virtualbox.conf
vboxdrv
vboxnetflt
vboxnetadp
dm-crypt
EOF

echo "papa ALL=(ALL) ALL" >> /etc/sudoers

echo -e "${GREEN} Installation terminée !${RESET}"
