#!/bin/bash
# Backup secrets to Amazon S3
# ------------------------------------------------------------------------------
set -o nounset
set -o errexit

function config() {
  THIS=$(readlink -f ${BASH_SOURCE[0]})
    PROJECT_DIR=$(dirname $THIS)
    . "$PROJECT_DIR/config.sh"

    if [[ ! -d "${STAGING_DIR}" ]]; then
      echo "Creating ${STAGING_DIR}"
      echo ""
      mkdir -p ${STAGING_DIR}
    fi
}

function build_staging() {
  rsync -avL --delete ${SOURCE} ${STAGING_DIR}
}

function sync_to_S3() {
  /usr/bin/duplicity \
  --s3-european-buckets \
  --s3-use-new-style \
  --encrypt-key=${GPG_KEY} \
  --asynchronous-upload \
  --verbosity notice \
  --full-if-older-than ${DAYS_TO_FULL_BACKUP}D \
  --archive-dir=${ARCHIVE_DIR} \
  --name=${NAME} \
  ${STAGING_DIR} ${REMOTE_DESTINATION}
}

config
build_staging
sync_to_S3

# Clean up
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
