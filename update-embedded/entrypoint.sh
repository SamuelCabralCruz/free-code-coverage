#!/bin/bash

DIR="$(dirname "$0")"
. "$DIR/shared/app.sh"
. "$DIR/shared/badge.sh"
. "$DIR/shared/github.sh"
. "$DIR/shared/validate.sh"
. "$DIR/shared/update.sh"
. "$DIR/shared/persistence/aws.sh"
<<<<<<< Updated upstream
<<<<<<< Updated upstream
. "$DIR/shared/reporter/workflow.sh"
=======
. "$DIR/shared/reporter/commit_status.sh"
>>>>>>> Stashed changes
=======
. "$DIR/shared/reporter/commit_status.sh"
>>>>>>> Stashed changes

validate_pull_request_context "$GITHUB_EVENT_NAME"

BUCKET_NAME=$1
PROJECT_NAME=$2
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
BYPASS_LABEL=$3
>>>>>>> Stashed changes
=======
BYPASS_LABEL=$3
>>>>>>> Stashed changes

BASE_BRANCH_NAME=$(jq -r '.pull_request.base.ref' "$GITHUB_EVENT_PATH" | tr  '/' '-')
BRANCH_NAME=$(jq -r '.pull_request.head.ref' "$GITHUB_EVENT_PATH" | tr  '/' '-')
EVENT_TYPE=$(jq -r '.action' "$GITHUB_EVENT_PATH")
<<<<<<< Updated upstream
<<<<<<< Updated upstream
IS_MERGED=$(jq -r '.pull_request.merged' "$GITHUB_EVENT_PATH")

set_up_persistence "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_REGION" "$BUCKET_NAME"
set_up_reporter tear_down_persistence
=======
=======
>>>>>>> Stashed changes
HAS_BYPASS_LABEL=$(jq ".pull_request | any(.labels[]; .name == \"$BYPASS_LABEL\")" "$GITHUB_EVENT_PATH")
IS_MERGED=$(jq -r '.pull_request.merged' "$GITHUB_EVENT_PATH")
STATUSES_URL=$(jq -r '.pull_request.statuses_url' "$GITHUB_EVENT_PATH")

set_up_persistence "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_REGION" "$BUCKET_NAME"
set_up_reporter "$GITHUB_TOKEN" "$STATUSES_URL" "$PROJECT_NAME"
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

validate_github_token "$GITHUB_TOKEN"
validate_project_name "$PROJECT_NAME"

if [[ $EVENT_TYPE == 'closed' ]]; then
  on_pull_request_closed "$PROJECT_NAME" "$BRANCH_NAME" "$BASE_BRANCH_NAME" "$IS_MERGED"
<<<<<<< Updated upstream
<<<<<<< Updated upstream
else
  echo 'This action is designed to be run with pull_request event types: closed. Quitting.'
  exit 1
fi
=======
=======
>>>>>>> Stashed changes
elif [[ $EVENT_TYPE =~ ^(labeled|unlabeled)$ ]]; then
  on_pull_request_labeled "$PROJECT_NAME" "$BRANCH_NAME" "$BASE_BRANCH_NAME" "$HAS_BYPASS_LABEL"
else
  echo 'This action is designed to be run with pull_request event types: unlabeled, labeled, and closed. Quitting.'
  exit 1
fi

tear_down_reporter
tear_down_persistence
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
