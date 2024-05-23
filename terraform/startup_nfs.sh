#!/bin/bash
set -e

# Update and install NFS server
sudo apt-get update -y
sudo apt-get install -y nfs-kernel-server

# Update GRUB configuration
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="scsi_mod.use_blk_mq=Y"/g' /etc/default/grub
sudo update-grub

# Zero superblocks on the NVMe devices
for dev in /dev/nvme0n1 /dev/nvme0n2; do
    sudo mdadm --zero-superblock $dev
done

# Create RAID 0 array
sudo mdadm --create --verbose /dev/md2 --level=0 --raid-devices=2 /dev/nvme0n1 /dev/nvme0n2

# Format the RAID array with ext4 filesystem
sudo mkfs.ext4 -F /dev/md2

# Add the new filesystem to /etc/fstab and create mount points
echo "/dev/md2 /data ext4 defaults 0 0" | sudo tee -a /etc/fstab
sudo mkdir -p /data/geoserver_data_directory /data/geoserver_gwc
sudo mount -a

# Set permissions for the directories
sudo chown -R nobody:nogroup /data/geoserver_data_directory /data/geoserver_gwc
sudo chmod -R 777 /data/geoserver_data_directory /data/geoserver_gwc

# Configure NFS exports
echo "/data/geoserver_data_directory *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
echo "/data/geoserver_gwc *(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

# Restart and enable NFS server
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server

# Disable google-startup-scripts
sudo systemctl disable google-startup-scripts

# Reboot the system
sudo reboot
