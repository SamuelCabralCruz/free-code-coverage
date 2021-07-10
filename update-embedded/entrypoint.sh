#!/bin/bash

DIR="$(dirname "$0")"
. "$DIR/shared/app.sh"
. "$DIR/shared/validate.sh"
. "$DIR/shared/update.sh"
. "$DIR/shared/persistence/aws.sh"

validate_pull_request_context "$GITHUB_EVENT_NAME"

BUCKET_NAME=$1
PROJECT_NAME=$2

BASE_BRANCH_NAME=$(jq -r '.pull_request.base.ref' "$GITHUB_EVENT_PATH" | tr  '/' '-')
BRANCH_NAME=$(jq -r '.pull_request.head.ref' "$GITHUB_EVENT_PATH" | tr  '/' '-')
EVENT_TYPE=$(jq -r '.action' "$GITHUB_EVENT_PATH")
IS_MERGED=$(jq -r '.pull_request.merged' "$GITHUB_EVENT_PATH")

set_up_persistence "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_REGION" "$BUCKET_NAME"

validate_project_name "$PROJECT_NAME"

if [[ $EVENT_TYPE == 'closed' ]]; then
  on_pull_request_closed "$PROJECT_NAME" "$BRANCH_NAME" "$BASE_BRANCH_NAME" "$IS_MERGED"
else
  echo 'This action is designed to be run with pull_request event types: closed. Quitting.'
  exit 1
fi

tear_down_persistence
