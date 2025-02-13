#!/bin/bash


DISK="/dev/sda"

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

# Ajouter les paquets nécessaires pour le support cryptographique
pacman -S grub os-prober efibootmgr nano sudo networkmanager hyprland firefox virtualbox virtualbox-host-dkms cryptsetup lvm2 --noconfirm
mkdir -p /boot/efi
mount ${DISK}1 /boot/efi

# Vérification UUID
echo -e "${CYAN}Vérification de l'UUID de la partition chiffrée...${RESET}"
CRYPT_UUID=$(blkid -s UUID -o value ${DISK}2)
echo "UUID utilisé : ${CRYPT_UUID}"

# Création du fichier crypttab
cat <<EOF > /etc/crypttab
lvm_crypt UUID=${CRYPT_UUID} none luks
EOF

# Configuration mkinitcpio avec l'ordre correct des hooks
sed -i 's/^HOOKS=(.*)$/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Configuration GRUB
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "GRUB_PRELOAD_MODULES=\"part_gpt cryptodisk lvm\"" >> /etc/default/grub

# Paramètre cryptdevice ESSENTIEL pour le démarrage
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${CRYPT_UUID}:vg0 root=/dev/mapper/vg0-root\"|" /etc/default/grub

# Réinstallation de GRUB avec vérification
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
