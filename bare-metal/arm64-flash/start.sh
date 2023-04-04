RELEASE=35 # The target Fedora Release. Use the same one that current FCOS is based on.
mkdir -p /tmp/RPi4boot/boot/efi/
sudo dnf install -y --downloadonly --release=$RELEASE --forcearch=aarch64 --destdir=/tmp/RPi4boot/  uboot-images-armv8 bcm283x-firmware bcm283x-overlays

for rpm in /tmp/RPi4boot/*rpm; do rpm2cpio $rpm | sudo cpio -idv -D /tmp/RPi4boot/; done
sudo mv /tmp/RPi4boot/usr/share/uboot/rpi_4/u-boot.bin /tmp/RPi4boot/boot/efi/rpi4-u-boot.bin

# Provide config.ign file to DISK
sudo coreos-installer install --architecture=aarch64 -i $CONFIG $FCOSDISK

# Mount ESP partition and copy files over
FCOSEFIPARTITION=$(lsblk $FCOSDISK -J -oLABEL,PATH  | jq -r '.blockdevices[] | select(.label == "EFI-SYSTEM")'.path)
mkdir /tmp/FCOSEFIpart
sudo mount $FCOSEFIPARTITION /tmp/FCOSEFIpart
sudo rsync -avh --ignore-existing /tmp/RPi4boot/boot/efi/ /tmp/FCOSEFIpart/
sudo umount $FCOSEFIPARTITION
