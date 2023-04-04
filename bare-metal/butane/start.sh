#!/bin/bash

input_dir=$1
output_dir=$2

echo $input_dir
echo $output_dir

# Strip trailing slashes
input_dir=$(echo "$input_dir" | sed 's:/*$::')
output_dir=$(echo "$output_dir" | sed 's:/*$::')


for file in `find ${input_dir} -maxdepth 1 -iname *.bu`; do
  filename=$(basename ${file%.*})
  /usr/local/bin/butane --pretty --strict "${file}" -o "${output_dir}/${filename}.ign"
done
