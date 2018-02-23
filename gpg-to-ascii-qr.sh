#!/bin/bash
# Run this script to generate an ASCII armoured export of a private GnuPG key.
# Note that the key should be passphrase-protected. If it is, the backup output
# will be encrypted - requiring the passphrase for usage.
#
# This script also generates a set of QR codes representing the key in a
# directory of your choice. Requires the `qrencode` utility.
# ------------------------------------------------------------------------------
set -o nounset
set -o errexit

function select_key() {
  gpg --list-keys
  echo "Please enter the reference for the GPG key you wish to backup:"
  read GPG_KEY
  echo "${GPG_KEY} selected."
}

function set_output_directory() {
  OUTPUT_DIR=$(zenity --file-selection --title="Select a directory to store the key backups." --filename=${HOME}/ --directory)
  case $? in
    0)
    echo "\"$OUTPUT_DIR\" selected.";;
    1)
    echo "No file selected.";;
    -1)
    echo "An unexpected error has occurred when setting the output directory.";;
  esac
  OUTPUT_FILE=${OUTPUT_DIR}/secret-${GPG_KEY}.asc
}

function export_secret_keys() {
  gpg --export-secret-keys -a ${GPG_KEY} > ${OUTPUT_FILE}
  echo "The GnuPG Key has been exported to ${OUTPUT_FILE}."
}

function create_qrencoded_images() {
  if [[ -x "$(command -v qrencode)" ]]; then
    cd ${OUTPUT_DIR}
    cat ${OUTPUT_FILE} | qrencode -S -v 40 -o ${OUTPUT_FILE}.gpg.png
    echo "Key split into multiple QR encoded images here: ${OUTPUT_DIR}"
  else
    echo "The qrencode package is not installed. See https://fukuchi.org/works/qrencode/index.html.en"
    echo "Or in Debian/Ubuntu run: sudo apt-get install qrencode."
  fi
}

select_key
set_output_directory
export_secret_keys
create_qrencoded_images
