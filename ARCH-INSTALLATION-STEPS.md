**INSTALLING ARCH WITH BTRFS, SNAPSHOTS, SDDM, HYPRLAND IN MULTI-GPU SETUP-NVIDIA GTX 1650, RYZEN 5 4600H**

# Increase font size
setfont ter-132b
  (or)
setfont -d

# Optional
pacman -Sy archlinux-keyring

# Check if rfkill blocks your interface and unblock them
1. rfkill
2. rfkill unblock all  -> to unblock if they are blocked

# Connect to internet and check
3. iwctl --passphrase "enter wifi password" station <network-interface> connect "wifi name"  -> network-interface can be wlan0, eno1, etc.
4. ping -c 3 google.com

# Time sync
5. timedatectl set-ntp true
6. timedatectl -> check ntp is active or true

# Format and Partition disk
7. lsblk
8. gdisk /dev/nvme0n1 -> It can be sda,sdb,etc based on your device.
   **INSIDE GDISK TO THESE STEPS AS FOLLOWS**
9. press **o** -> creates new empty GPT table -> confirm with **y**
10. press **n** -> new partition -> press enter till you see last sector -> **+1G** -> partition code **ef00**
11. press **n** -> new partition -> press enter till you see partition code **8300**
12. press **w** -> write and exit -> confirm with **y**
13. lsblk /dev/nvme0n1 -> Verify the parition
14. mkfs.fat -F32 -n EFI /dev/nvmeon1p1 -> it may be sda1 if sda is the label of your ssd or others
15. mkfs.btrfs -L ARCH /dev/nvme0n1p2

# Creating BTRFS subvolumes
16. mount /dev/nvme0n1p2
17. btrfs subvolume create /mnt/@
18. btrfs subvolume create /mnt/@home
19. btrfs subvolume create /mnt/@snapshots
20. btrfs subvolume create /mnt/@var_log
21. btrfs subvolume create /mnt/@var_cache
22. btrfs subvolume list /mnt -> verify
23. umount /mnt

# Mounting
24. mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@ /dev/nvme0n1p2 /mnt
25. mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache}
26. mount /dev/sda1 /mnt/boot
27. mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home /dev/sda2 /mnt/home
28. mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@snapshots /dev/sda2 /mnt/.snapshots
29. mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@var_log /dev/sda2 /mnt/var/log
30. mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@var_cache /dev/sda2 /mnt/var/cache
31. lsblk -> verify

# Install base system
32. reflector --country India --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist -> Change it based on your location for getting faster downloads
33. pacstrap -K /mnt base base-devel linux linux-lts linux-headers linux-lts-headers linux-firmware amd-ucode btrfs-progs \
                     grub efibootmgr grub-btrfs inotify-tools networkmanager pipewire pipewire-pulse pipewire-alsa wireplumber \
                     mesa vulakn-radeon libva-mesa-driver nvidia-open nvidia-utils nvidia-prime git curl wget vim neovim man-db man-pages \
                     sudo bash bash-completion sof-firmware ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-font-awesome plocate tree fzf snapper snap-pac               -> sof-firmware for lenovo legion specific                

# Generate fstab
34. genfstab -U /mnt >> /mnt/etc/fstab
35. cat /mnt/etc/fstab -> verify

# Chroot into new system
36. arch-chroot /mnt

# System Configuration
**Timezone**
37. ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime -> change timezone to your specifics
38. hwclock --systohc
**Locale**
39. vim /etc/locale.gen
40. Find and uncomment en_US.UTF-8 UTF-8
41. locale-gen
42. echo "LANG=en_US.UTF-8" > /etc/locale.conf
**Hostname**
43. echo "legion" > /etc/hostname -> can be anything to your taste
**Keymap**
44. echo "KEYMAP=us" > /etc/vconsole.conf
**Hosts file**
45. vim /etc/hosts
46. Add this at last, 127.0.1.1    legion.localdomain legion -> change it according to your host name
**Root Password**
47. passwd -> Then type to set new root password
**Create your user**
48. useradd -m -G wheel,audio,video,storage,optical -s /bin/bash <yourusername> -> To add user
49. passwd <yourusername> -> To set password for your user
**Enable sudoers wheel group**
50. EDITOR=vim visudo
51. uncomment this line, %wheel ALL=(ALL:ALL) ALL
**mkinitcpio (Initramfs)**
52. vim /etc/mkinitcpio.conf
53. Find MODULES=() and set, MODULES=(amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm)
54. Find HOOKS(...) and remove kms, HOOKS=(base systemd autodetect microcode modconf keyboard sd-vconsole block filesystems fsck) -> systemd can be udevd and certain things may differ so just make sure to only remove kms
55. mkinitcpio -P -> Verify if image creation is successful not may be not fully complete or any error
**GRUB bootloader**
56. grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH
57. vim /etc/default/grub
58. Set kernel parameters, find and modify this and add or uncomment the next 2 steps too till step 60 , GRUB_CMDLINE_LINUX_DEFAULT="quiet loglevel=3 nvidia_drm.modeset=1 nvidia_drm.fbdev=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1"
59. GRUB_DISABLE_OS_PROBER=false
60. GRUB_BTRFS_SHOW_TOTAL_SNAPSHOTS_FOUND=true
61. grub-mkconfig -o /boot/grub/grub.cfg

# Enable essential services
62. systemctl enable NetworkManager
63. systemctl enable fstrim.timer
64. systemctl enable nvidia-suspend.service
65. systemctl enable nvidia-hibernate.service
66. systemctl enable nvidia-resume.service

# Set up Snapper
67. umount /.snapshots
68. rm -rf /.snapshots
69. snapper --no-dbus -c root create-config /
70. btrfs subvolume delete /.snapshots
71. mkdir /.snapshots
72. mount -a
73. chmod 750 /.snapshots
74. chown :wheel /.snapshots
75. findmnt /.snapshots -> verify
76. btrfs sunvolume list / -> verify snapshots in the list
77. vim /etc/snapper/configs/root
78. Find and set these values:

ALLOW_GROUPS="wheel"
NUMBER_CLEANUP=yes
NUMBER_MIN_AGE=1800
NUMBER_LIMIT=10
NUMBER_LIMIT_IMPORTANT=10
TIMELINE_CREATE=yes
TIMELINE_CLEANUP=yes
TIMELINE_MIN_AGE=1800
TIMELINE_LIMIT_HOURLY=5
TIMELINE_LIMIT_DAILY=7
TIMELINE_LIMIT_WEEKLY=3
TIMELINE_LIMIT_MONTHLY=2
TIMELINE_LIMIT_YEARLY=1

80. systemctl enable snapper-timeline.timer
81. systemctl enable snapper-cleanup.timer
82. systemctl enable grub-btrfsd

# Exit and Reboot
83. exit
84. umount -R /mnt
85. reboot



# First Boot Setup
86. nmtui -> Activate your wifi connection
87. sudo vim /etc/pacman.conf
88. Find and uncomment [multilib] and the line below it
89. pacman -Syu
**Install yay**
90. cd /tmp
91. git clone https://aur.archlinux.org/yay.git
92. cd yay
93. makepkg -si
**Multi-gpu consistent symlink**
94. See the file in the dotfiles folder called amd-igu rules and do that for hyprland to use amdgpu as display gpu and for all and use nvidia as offload using nvidia-prime. For more clear step by step info visit https://wiki.hypr.land/Configuring/Multi-GPU/

# Hyprland Installation
95. sudo pacman -Syu
96. sudo pacman -S hyprland wayland-protocols xorg-xwayland qt5-wayland qt6-wayland \
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  pipewire wireplumber pipewire-audio pipewire-pulse \
  waybar dunst libnotify sddm kitty alacritty rofi-wayland hyprpaper hyprlock firefox \
  bluez bluez-utils blueman \
  wl-clipboard clip-hist grim slurp \
  htop fastfetch btop brightnessctl pamixer \
  polkit-gnome noto-fonts-emoji --needed
97. yay -S hyprshutdown
98. sudo systemctl enable sddm
99. reboot

# Copy from my dotfiles repo
100. Can clone or copy individual necessary files or folder like waybar, rofi, hypr, etc which also 
      includes scripts and rofi menu for essential things like bluetooth wifi brightness volume, wallpaper, 
      screen orientation,etc, some key files for gpu setup and black screen fix for sleep crash by nvidia gpu and all.


