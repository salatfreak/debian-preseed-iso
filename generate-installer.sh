#!/bin/bash

# Configure shell
set -euo pipefail
shopt -s extglob

# Main function
main() {
  # Parse arguments
  local args; args="$(
    getopt -q -o i:o:p:f:h \
      -l input:,output:,preseed:,file:,quiet,help -- "$@"
  )" || abort 'Invalid arguments'
  eval set -- "$args"

  # Get options and parameters
  local input output preseed
  local files=()
  while [[ "$1" != '--' ]]; do
    case "$1" in
      -i | --input    ) shift;  input="$1";;
      -o | --output   ) shift;  output="$1";;
      -p | --preseed  ) shift;  preseed="$1";;
      -f | --file     ) shift;  files+=("$1");;
      -h | --help     )         usage; exit;;
    esac
    shift
  done
  shift

  # Validate parameters
  (( $# == 0 ))     || abort "Unexpected positional parameter \"$1\""
  [[ -v input ]]    || abort 'Required input parameter missing'
  [[ -v output ]]   || abort 'Required output parameter missing'
  [[ -v preseed ]]  || abort 'Required preseed parameter missing'

  # Make temporary directory
  local tmp; tmp="$(mktemp -d)" ||
    abort 'Creating temporary directory failed'
  trap "rm -rf $(quote "$tmp")" EXIT

  # Extract input image
  7z x -o"$tmp" "$input" >/dev/null || abort 'Extracting input image failed'

  # Add preseed file
  cp "$preseed" "$tmp/preseed.cfg" || abort 'Copying preseed file failed'
  chmod 644 "$tmp/preseed.cfg" || abort 'Setting preseed file perms failed'

  # Add custom files
  for f in "${files[@]}"; do
    cp "$f" "$tmp/" || abort "Copying file \"$f\" failed"
  done

  # Activate auto installation
  sed -i "$tmp/isolinux/isolinux.cfg" \
    -e 's/^timeout 0$/timeout 1/' ||
    abort 'Modifying isolinux/isolinux.cfg failed'
  sed -i "$tmp/isolinux/gtk.cfg" \
    -e 's/^\tappend /\tappend auto=true file=\/cdrom\/preseed.cfg /' ||
    abort 'Modifying isolinux/gtk.cfg failed'

  # Regenerate md5sum
  pushd "$tmp" > /dev/null
  find -follow -type f ! -name md5sum.txt -print0 |
    xargs -0 md5sum > md5sum.txt ||
    abort 'Generating MD5 sum failed'
  popd > /dev/null

  # Create output .iso file
  genisoimage -quiet -r -J \
    -b isolinux/isolinux.bin -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -o "$output" "$tmp" || abort 'Creating output .iso file failed'
}

# Print usage info
usage() {
  cat <<END
Usage: generate-installer.sh -i INPUT -o OUTPUT [-p PRESEED] [-f FILE]... [-h]

Generates an ISO for automated Debian installation with preseeding.

Options:
  -i  --input     Set image to base installer on
  -o  --output    Set file to write installer to
  -p  --preseed   Set preseed file to configure installer
  -f  --file      Add file to add to the .iso image
  -h  --help      Show this help and exit
END
}

# Quote string
quote () { printf "'%s'" "${1//\'/\'\\\'\'}"; }

# Abort with error
abort() { local msg="$1"
  echo "[ERROR] $msg" >&2
  exit 1
}

# Call main function
main "$@"
