#!/bin/bash

DIR="$(dirname "$0")"
. "$DIR/shared/app.sh"
. "$DIR/shared/badge.sh"
. "$DIR/shared/github.sh"
. "$DIR/shared/validate.sh"
. "$DIR/shared/upload.sh"
. "$DIR/shared/persistence/aws.sh"
. "$DIR/shared/reporter/commit_status.sh"

validate_pull_request_context "$GITHUB_EVENT_NAME"

BUCKET_NAME=$1
PROJECT_NAME=$2
COVERAGE_METRIC=$3
COVERAGE_REPORT=$4
BADGE_COLOR_THRESHOLDS=$5
BYPASS_LABEL=$6

BASE_BRANCH_NAME=$(jq -r '.pull_request.base.ref' "$GITHUB_EVENT_PATH" | tr  '/' '-')
BRANCH_NAME=$(jq -r '.pull_request.head.ref' "$GITHUB_EVENT_PATH" | tr  '/' '-')
CREATE_COVERAGE_REPORT_COMMENT_URL=$(jq -r '.pull_request.comments_url' "$GITHUB_EVENT_PATH")
EVENT_TYPE=$(jq -r '.action' "$GITHUB_EVENT_PATH")
HAS_BYPASS_LABEL=$(jq ".pull_request | any(.labels[]; .name == \"$BYPASS_LABEL\")" "$GITHUB_EVENT_PATH")
STATUSES_URL=$(jq -r '.pull_request.statuses_url' "$GITHUB_EVENT_PATH")

set_up_persistence "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" "$AWS_REGION" "$BUCKET_NAME"
set_up_reporter "$GITHUB_TOKEN" "$STATUSES_URL" "$PROJECT_NAME"

validate_github_token "$GITHUB_TOKEN"
validate_project_name "$PROJECT_NAME"
validate_coverage_metric "$COVERAGE_METRIC"
validate_badge_color_thresholds "$BADGE_COLOR_THRESHOLDS"

if [[ $EVENT_TYPE =~ ^(opened|reopened|synchronize)$ ]]; then
  upload "$GITHUB_TOKEN" "$PROJECT_NAME" "$BRANCH_NAME" "$BASE_BRANCH_NAME" "$COVERAGE_METRIC" "$CREATE_COVERAGE_REPORT_COMMENT_URL" "$COVERAGE_REPORT" "$BADGE_COLOR_THRESHOLDS" "$HAS_BYPASS_LABEL"
else
  echo 'This action is designed to be run with pull_request event types: opened, reopened, and synchronize. Quitting.'
  exit 1
fi

tear_down_reporter
tear_down_persistence
