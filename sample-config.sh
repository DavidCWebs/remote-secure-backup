export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
TIMESTAMP=$(date "+%Y-%m-%d-%H:%M:%S")
SOURCE="/path/to/source"
STAGING_DIR="/path/to/staging"
REMOTE_DESTINATION="s3+http://your-bucket-name/subdir/"
ARCHIVE_DIR="/path/to/custom-duplicity-archives/"
GPG_KEY="XXXXXXXX"

function clean_up() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
}
