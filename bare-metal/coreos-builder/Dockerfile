FROM quay.io/coreos/coreos-installer:release

ENTRYPOINT coreos-installer iso customize \
  --dest-device $DEVICE \
  --dest-ignition $IGNITION \
  -o /out/$ISO \
  $COREOS_ISO
