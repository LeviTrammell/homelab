#!/bin/bash
set -euxo pipefail

boot_device="/dev/$(basename $(readlink -f /sys/class/block/mmcblk?))"
wipefs --all $boot_device
blkdiscard $boot_device

tee -a /etc/coreos/installer.d/0001_override.yaml << END
ignition-file: /etc/coreos/dest.ign
dest-device: ${boot_device}
END
