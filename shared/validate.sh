#!/bin/bash

validate_badge_color_thresholds() {
  local BADGE_COLOR_THRESHOLDS=$1
  local THRESHOLDS
  if [[ -n "$BADGE_COLOR_THRESHOLDS" ]]; then
    IFS=',' read -r -a THRESHOLDS <<< "$BADGE_COLOR_THRESHOLDS"
    if [[ ${#THRESHOLDS[@]} -ne 5 ]]; then
      echo "badge-color-thresholds must be a comma-separated list of 5 strictly increasing numbers between 0 and 100 with at most one digit. Quitting."
      exit 1
    fi
    for threshold in "${THRESHOLDS[@]}"
    do
      if [[ ! "$threshold" =~ $COVERAGE_METRIC_REGEX ]]; then
        echo "badge-color-thresholds must be a comma-separated list of 5 strictly increasing numbers between 0 and 100 with at most one digit. Quitting."
        exit 1
      fi
    done
    local SORTED=($(echo "${THRESHOLDS[*]}" | tr " " "\n" | sort))
    local DIFF
    DIFF=$(diff <(printf "%s\n" "${THRESHOLDS[@]}") <(printf "%s\n" "${SORTED[@]}"))
    if [[ -n "$DIFF" ]]; then
      echo "badge-color-thresholds must be a comma-separated list of 5 strictly increasing numbers between 0 and 100 with at most one digit. Quitting."
      exit 1
    fi
  fi
}

validate_coverage_metric() {
  local COVERAGE_METRIC=$1
  if [[ -z "$COVERAGE_METRIC" ]]; then
    echo "coverage-metric input is required. Quitting."
    exit 1
  fi
  local COVERAGE_METRIC_REGEX='^(100(\.0)?|\d{1,2}(\.\d)?)$'
  if [[ ! "$COVERAGE_METRIC" =~ $COVERAGE_METRIC_REGEX ]]; then
    echo "coverage-metric must be a number between 0 and 100 with at most one digit. Quitting."
    exit 1
  fi
}

validate_github_token() {
  local GITHUB_TOKEN=$1
  if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "GITHUB_TOKEN env variable is not set. Quitting."
    exit 1
  fi
}

validate_project_name() {
  local PROJECT_NAME=$1
  if [[ -z "$PROJECT_NAME" ]]; then
    echo "project-name input is required. Quitting."
    exit 1
  fi
  if [[ ! "$PROJECT_NAME" =~ ^[a-z\-]+$ ]]; then
    echo "project-name input is invalid. It should be a lower case kebab string (regex: [a-z\-]+). Quitting."
    exit 1
  fi
}

validate_pull_request_context() {
  local GITHUB_EVENT_NAME=$1
  if [[ $GITHUB_EVENT_NAME != 'pull_request' ]]; then
    echo "This action is designed to be run in pull request context. Quitting."
    exit 1
  fi
}
