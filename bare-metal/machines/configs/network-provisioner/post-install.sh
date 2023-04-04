#!/usr/bin/bash

boot_device="/dev/$(basename $(readlink -f /sys/class/block/mmcblk?))"

# remove all the boot options.
efibootmgr | sed -nE 's,^Boot([0-9A-F]{4}).*,\1,gp' | xargs -I% efibootmgr --quiet --delete-bootnum --bootnum %

# Add a boot option. Needed for Beelink T4 Pros
efibootmgr -c -d "${boot_device}" -p 2 -L Fedora -l '\EFI\fedora\shimx64.efi'
