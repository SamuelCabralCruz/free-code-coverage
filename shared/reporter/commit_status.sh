#!/bin/bash

set_up_reporter() {
  local GITHUB_TOKEN=$1
  local STATUSES_URL=$2
  local PROJECT_NAME=$3
  echo "local GITHUB_TOKEN=\"$GITHUB_TOKEN\"" > reporter_config.txt
  echo "local STATUSES_URL=\"$STATUSES_URL\"" >> reporter_config.txt
  echo "local PROJECT_NAME=\"$PROJECT_NAME\"" >> reporter_config.txt
}

tear_down_reporter() {
  rm reporter_config.txt
}

report_failure() {
  . "reporter_config.txt"
  local COVERAGE_METRIC=$1
  local PREVIOUS_COVERAGE_METRIC=$2
  curl --request POST \
    --url "$STATUSES_URL" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --header 'content-type: application/json' \
    --header 'accept: application/vnd.github.v3+json' \
    --data "{\"state\": \"failure\", \"description\": \"PR: ${COVERAGE_METRIC}% vs Base: ${PREVIOUS_COVERAGE_METRIC}%\",\"context\": \"Code Coverage - ${PROJECT_NAME}\"}" \
    -o create_commit_status.txt &> /dev/null
}

report_success() {
  . "reporter_config.txt"
  local COVERAGE_METRIC=$1
  curl --request POST \
    --url "$STATUSES_URL" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --header 'content-type: application/json' \
    --header 'accept: application/vnd.github.v3+json' \
    --data "{\"state\": \"success\", \"description\": \"${COVERAGE_METRIC}%\",\"context\": \"Code Coverage - ${PROJECT_NAME}\"}" \
    -o create_commit_status.txt &> /dev/null
}

report_bypass() {
  . "reporter_config.txt"
  local COVERAGE_METRIC=$1
  curl --request POST \
    --url "$STATUSES_URL" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --header 'content-type: application/json' \
    --header 'accept: application/vnd.github.v3+json' \
    --data "{\"state\": \"success\", \"description\": \"${COVERAGE_METRIC}% (BYPASS)\",\"context\": \"Code Coverage - ${PROJECT_NAME}\"}" \
    -o create_commit_status.txt &> /dev/null
}
