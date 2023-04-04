#!/bin/bash

input_dir=$1
output_dir=$2

echo $input_dir
echo $output_dir

# Strip trailing slashes
input_dir=$(echo "$input_dir" | sed 's:/*$::')
output_dir=$(echo "$output_dir" | sed 's:/*$::')

for file in `find ${input_dir} -maxdepth 1 -iname *.bu`; do
  /usr/sbin/coreos-installer iso customize \
    

  coreos-installer iso customize \
  --dest-device $DEVICE \
  --dest-ignition $IGNITION \
  -o /out/$ISO \
  $COREOS_ISO


  /usr/local/bin/butane --pretty --strict "${file}" -o "${output_dir}/${filename}.ign"
done

