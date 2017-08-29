#!/bin/bash
function config() {
  THIS=$(readlink -f ${BASH_SOURCE[0]})
    PROJECT_DIR=$(dirname $THIS)
    . "$PROJECT_DIR/config.sh"
}

function set_target() {
  TARGET_PARENT=$(zenity --file-selection --title="Select a parent directory for the restored data." --filename=${PWD}/ --directory)
  case $? in
    0)
    echo "\"$TARGET_PARENT\" selected.";;
    1)
    echo "No file selected.";;
    -1)
    echo "An unexpected error has occurred.";;
  esac
  TARGET="${TARGET_PARENT}/${TIMESTAMP}"
}

function restore() {
  /usr/bin/duplicity restore \
  --s3-european-buckets \
  --s3-use-new-style \
  ${REMOTE_DESTINATION} ${TARGET}
}

config
set_target
restore
clean_up
