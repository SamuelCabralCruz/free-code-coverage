#!/bin/bash

set_up_persistence() {
  echo 'set up persistence'
  local AWS_ACCESS_KEY_ID=$1
  local AWS_SECRET_ACCESS_KEY=$2
  local AWS_REGION=$3
  local BUCKET_NAME=$4
  set_up_aws_profile "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_REGION"
  validate_bucket_name "$BUCKET_NAME"
  echo "$BUCKET_NAME" > persistence_config.txt
}

set_up_aws_profile() {
  local AWS_ACCESS_KEY_ID=$1
  local AWS_SECRET_ACCESS_KEY=$2
  local AWS_REGION=$3
  if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
    echo "AWS_ACCESS_KEY_ID env variable is not set. Quitting."
    exit 1
  fi
  if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "AWS_SECRET_ACCESS_KEY env variable is not set. Quitting."
    exit 1
  fi
  if [[ -z "$AWS_REGION" ]]; then
    AWS_REGION="us-east-1"
  fi
  aws configure --profile free-code-coverage <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF
}

validate_bucket_name() {
  local BUCKET_NAME=$1
  if [[ -z "$BUCKET_NAME" ]]; then
    echo "bucket-name input is required. Quitting."
    exit 1
  fi
  local IS_REACHABLE
  IS_REACHABLE=$(is_bucket_reachable "$BUCKET_NAME")
  if [[ "$IS_REACHABLE" == 'false' ]]; then
    echo "Unreachable S3 bucket. Quitting."
    exit 1
  fi
}

is_bucket_reachable() {
  local BUCKET_NAME=$1
  aws s3 ls "$BUCKET_NAME" --profile free-code-coverage &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo 'true'
  else
    echo 'false'
  fi
}

tear_down_persistence() {
  echo 'tear down persistence'
  tear_down_aws_profile
  rm persistence_config.txt
}

tear_down_aws_profile() {
  aws configure --profile free-code-coverage <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
}

get_bucket_name() {
  cat persistence_config.txt
}

to_uri() {
  local BUCKET_NAME
  BUCKET_NAME=$(get_bucket_name)
  local FILE_NAME=$1
  echo "s3://$BUCKET_NAME/$FILE_NAME"
}

has_file() {
  local FILE_NAME=$1
  aws s3 ls "$(to_uri "$FILE_NAME")" --profile free-code-coverage &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo 'true'
  else
    echo 'false'
  fi
}

get_file() {
  local FILE_NAME=$1
  aws s3 cp "$(to_uri "$FILE_NAME")" "$FILE_NAME" --profile free-code-coverage
}

set_file() {
  local FILE_NAME=$1
  aws s3 cp "$FILE_NAME" "$(to_uri "$FILE_NAME")" --profile free-code-coverage
}

set_publicly_readable_file() {
  local FILE_NAME=$1
  aws s3 cp "$FILE_NAME" "$(to_uri "$FILE_NAME")" --acl public-read --cache-control no-cache --profile free-code-coverage
}

delete_file() {
  local FILE_NAME=$1
  aws s3 rm "$(to_uri "$FILE_NAME")" --profile free-code-coverage
}

rename_file() {
  local FROM_FILE=$1
  local TO_FILE=$2
  aws s3 mv "$(to_uri "$FROM_FILE")" "$(to_uri "$TO_FILE")" --profile free-code-coverage
}

rename_publicly_readable_file() {
  local FROM_FILE=$1
  local TO_FILE=$2
  aws s3 mv "$(to_uri "$FROM_FILE")" "$(to_uri "$TO_FILE")" --acl public-read --profile free-code-coverage
}

