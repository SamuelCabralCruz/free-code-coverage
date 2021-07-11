#!/bin/bash

DIR="$(dirname "$0")"
. "$DIR/shared/app.sh"
. "$DIR/shared/validate.sh"
. "$DIR/shared/update.sh"
. "$DIR/shared/persistence/github.sh"
. "$DIR/shared/reporter/commit_status.sh"

validate_pull_request_context "$GITHUB_EVENT_NAME"

GITHUB_REPO=$1
PROJECT_NAME=$2
BYPASS_LABEL=$3

BASE_BRANCH_NAME=$(jq -r '.pull_request.base.ref' "$GITHUB_EVENT_PATH" | tr  '/' '-')
BRANCH_NAME=$(jq -r '.pull_request.head.ref' "$GITHUB_EVENT_PATH" | tr  '/' '-')
EVENT_TYPE=$(jq -r '.action' "$GITHUB_EVENT_PATH")
HAS_BYPASS_LABEL=$(jq ".pull_request | any(.labels[]; .name == \"$BYPASS_LABEL\")" "$GITHUB_EVENT_PATH")
IS_MERGED=$(jq -r '.pull_request.merged' "$GITHUB_EVENT_PATH")
STATUSES_URL=$(jq -r '.pull_request.statuses_url' "$GITHUB_EVENT_PATH")

set_up_persistence "$GITHUB_TOKEN" "$GITHUB_REPO"
set_up_reporter "$GITHUB_TOKEN" "$STATUSES_URL" "$PROJECT_NAME"

validate_project_name "$PROJECT_NAME"

if [[ $EVENT_TYPE == 'closed' ]]; then
  on_pull_request_closed "$PROJECT_NAME" "$BRANCH_NAME" "$BASE_BRANCH_NAME" "$IS_MERGED"
elif [[ $EVENT_TYPE =~ ^(labeled|unlabeled)$ ]]; then
  on_pull_request_labeled "$PROJECT_NAME" "$BRANCH_NAME" "$BASE_BRANCH_NAME" "$HAS_BYPASS_LABEL"
else
  echo 'This action is designed to be run with pull_request event types: unlabeled, labeled, and closed. Quitting.'
  exit 1
fi

tear_down_reporter
tear_down_persistence
