#!/bin/bash

# --- Couleurs (optionnel) ---
RED="\e[31m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

DISK="/dev/sda"  # Adapter si besoin
echo -e "${CYAN}Configuration du système en chroot...${RESET}"

# 1) Fuseau horaire & horloge
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
echo "archlinux" > /etc/hostname

# 2) Installation des paquets essentiels
pacman -S --noconfirm grub os-prober efibootmgr nano sudo networkmanager \
                      hyprland firefox virtualbox virtualbox-host-dkms \
                      cryptsetup lvm2

# 3) Monter /boot/efi (pour réinstaller GRUB EFI si besoin)
mkdir -p /boot/efi
mount "${DISK}1" /boot/efi

# 4) Récupération de l'UUID de la partition chiffrée
CRYPT_UUID=$(blkid -s UUID -o value "${DISK}2")
echo -e "${CYAN}UUID de la partition LUKS : ${CRYPT_UUID}${RESET}"

# 5) Configuration /etc/crypttab
cat <<EOF > /etc/crypttab
lvm_crypt UUID=${CRYPT_UUID} none luks
EOF

# 6) Configuration de mkinitcpio
# On remplace toute la ligne HOOKS=... par notre suite de hooks
# (ordre important : encrypt puis lvm2)
sed -i 's|^HOOKS=.*|HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)|' /etc/mkinitcpio.conf

# 7) Configuration de /etc/default/grub
#    - GRUB_ENABLE_CRYPTODISK=y pour demander à GRUB de gérer LUKS2
#    - cryptdevice=UUID=xxx:lvm_crypt root=... pointe vers /dev/mapper/vg0-root
{
  echo "GRUB_ENABLE_CRYPTODISK=y"
  echo "GRUB_PRELOAD_MODULES=\"luks2 part_gpt cryptodisk gcry_rijndael gcry_sha512 lvm ext2\""
  echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${CRYPT_UUID}:lvm_crypt root=/dev/mapper/vg0-root\""
} > /etc/default/grub

# (Facultatif) Si on veut être sûr de forcer la ligne CMDLINE_LINUX :
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${CRYPT_UUID}:lvm_crypt root=/dev/mapper/vg0-root\"|" /etc/default/grub

# 8) Activation du VG au cas où
vgchange -ay

# 9) Regénération de l’initramfs
mkinitcpio -P

# 10) Installation du chargeur GRUB en mode EFI
grub-install --target=x86_64-efi \
             --efi-directory=/boot/efi \
             --modules="luks2 part_gpt cryptodisk gcry_rijndael gcry_sha512 lvm ext2" \
             --recheck

# 11) Génération de grub.cfg
grub-mkconfig -o /boot/grub/grub.cfg

# 12) Réactivation initramfs (pas forcément indispensable, mais on peut le faire)
mkinitcpio -P

# 13) Activation NetworkManager
systemctl enable NetworkManager

# 14) Création utilisateurs (exemple)
useradd -m -s /bin/bash papa
echo "papa:azerty123" | chpasswd

useradd -m -s /bin/bash fiston
echo "fiston:azerty123" | chpasswd

# Droits VirtualBox
mkdir -p "/home/papa/VirtualBox VMs/"
chown -R papa:papa "/home/papa/VirtualBox VMs/"
chmod 777 "/home/papa/VirtualBox VMs/"

# 15) Modules à charger au démarrage (facultatif)
cat <<EOF > /etc/modules-load.d/virtualbox.conf
vboxdrv
vboxnetflt
vboxnetadp
dm-crypt
EOF

# 16) Sudo pour l’utilisateur "papa"
echo "papa ALL=(ALL) ALL" >> /etc/sudoers

# (Optionnel) Éviter de fermer le volume chiffré depuis le chroot : ça provoque souvent une erreur
# cryptsetup close lvm_crypt

echo -e "${GREEN}Configuration chroot terminée avec succès !${RESET}"
