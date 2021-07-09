#!/bin/bash

publish_coverage_report() {
  local GITHUB_TOKEN=$1
  local PROJECT_NAME=$2
  local BRANCH_NAME=$3
  local CREATE_COVERAGE_REPORT_COMMENT_URL=$4
  local COVERAGE_REPORT=$5
  local COVERAGE_REPORT_COMMENT_URL_FILE_NAME="coverage-report-comment-url-$PROJECT_NAME-$BRANCH_NAME.txt"
  local HAS_FILE
  HAS_FILE=$(has_file "$COVERAGE_REPORT_COMMENT_URL_FILE_NAME")
  if [[ "$HAS_FILE" == 'true' ]]; then
    echo 'Deleting previous coverage report comment.'
    get_file "$COVERAGE_REPORT_COMMENT_URL_FILE_NAME"
    local DELETE_COVERAGE_REPORT_COMMENT_URL
    DELETE_COVERAGE_REPORT_COMMENT_URL=$(cat "$COVERAGE_REPORT_COMMENT_URL_FILE_NAME")
    local OUTPUT_FILE="delete_coverage_report_comment.txt"
    delete_pull_request_comment "$GITHUB_TOKEN" "$DELETE_COVERAGE_REPORT_COMMENT_URL" "$OUTPUT_FILE"
  else
    echo 'No previous coverage report comment to delete.'
  fi
  echo 'Commenting pull request with coverage report.'
  local OUTPUT_FILE="create_coverage_report_comment.txt"
  create_pull_request_comment "$GITHUB_TOKEN" "$CREATE_COVERAGE_REPORT_COMMENT_URL" "$COVERAGE_REPORT" "$OUTPUT_FILE"
  jq -r '.url' "$OUTPUT_FILE" > "$COVERAGE_REPORT_COMMENT_URL_FILE_NAME"
  set_file "$COVERAGE_REPORT_COMMENT_URL_FILE_NAME"
}

upload_coverage_metric() {
  local PROJECT_NAME=$1
  local BRANCH_NAME=$2
  local COVERAGE_METRIC=$3
  local COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt"
  echo "$COVERAGE_METRIC" > "$COVERAGE_METRIC_FILE_NAME"
  set_file "$COVERAGE_METRIC_FILE_NAME"
}

upload_badge() {
  local PROJECT_NAME=$1
  local BRANCH_NAME=$2
  local BADGE_COLOR_THRESHOLDS=$3
  local COVERAGE_METRIC=$4
  local BADGE_COLOR
  BADGE_COLOR=$(compute_badge_color "$BADGE_COLOR_THRESHOLDS" "$COVERAGE_METRIC")
  local BADGE_FILE_NAME
  BADGE_FILE_NAME="badge-$PROJECT_NAME-$BRANCH_NAME.svg"
  fetch_badge "$PROJECT_NAME" "$COVERAGE_METRIC" "$BADGE_COLOR" "$BADGE_FILE_NAME"
  set_publicly_readable_file "$BADGE_FILE_NAME"
}

fetch_coverage_metric() {
  local PROJECT_NAME=$1
  local BASE_BRANCH_NAME=$2
  local DEFAULT=$3
  local PREVIOUS_COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BASE_BRANCH_NAME.txt"
  local HAS_FILE
  HAS_FILE=$(has_file "$PREVIOUS_COVERAGE_METRIC_FILE_NAME")
  if [[ "$HAS_FILE" == 'true' ]]; then
    echo 'Previous coverage metric found.'
    get_file "$PREVIOUS_COVERAGE_METRIC_FILE_NAME"
    FETCHED_COVERAGE_METRIC=$(cat "$PREVIOUS_COVERAGE_METRIC_FILE_NAME")
  else
    echo "No previous coverage metric found. Defaulting to $DEFAULT%."
    FETCHED_COVERAGE_METRIC=$DEFAULT
  fi
}

is_coverage_decrease() {
  local COVERAGE_METRIC=$1
  local PREVIOUS_COVERAGE_METRIC=$2
  if (( $(echo "$COVERAGE_METRIC < $PREVIOUS_COVERAGE_METRIC" | bc -l) )); then
    echo 'true'
  else
    echo 'false'
  fi
}

override_coverage_file() {
  local PROJECT_NAME=$1
  local BRANCH_NAME=$2
  local BASE_BRANCH_NAME=$3
  COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt"
  BASE_COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BASE_BRANCH_NAME.txt"
  rename_file "$COVERAGE_METRIC_FILE_NAME" "$BASE_COVERAGE_METRIC_FILE_NAME"
}

override_badge_file() {
  local PROJECT_NAME=$1
  local BRANCH_NAME=$2
  local BASE_BRANCH_NAME=$3
  BADGE_FILE_NAME="badge-$PROJECT_NAME-$BRANCH_NAME.svg"
  BASE_BADGE_FILE_NAME="badge-$PROJECT_NAME-$BASE_BRANCH_NAME.svg"
  rename_publicly_readable_file "$BADGE_FILE_NAME" "$BASE_BADGE_FILE_NAME"
}
