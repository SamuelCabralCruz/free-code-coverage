upload() {
  local GITHUB_TOKEN=$1
  local PROJECT_NAME=$2
  local BRANCH_NAME=$3
  local BASE_BRANCH_NAME=$4
  local COVERAGE_METRIC=$5
  local CREATE_COVERAGE_REPORT_COMMENT_URL=$6
  local COVERAGE_REPORT=$7
  local BADGE_COLOR_THRESHOLDS=$8
  local HAS_BYPASS_LABEL=$9

  if [[ -n "$COVERAGE_REPORT" ]]; then
    publish_coverage_report "$GITHUB_TOKEN" "$PROJECT_NAME" "$BRANCH_NAME" "$CREATE_COVERAGE_REPORT_COMMENT_URL" "$COVERAGE_REPORT"
  fi
  upload_coverage_metric "$PROJECT_NAME" "$BRANCH_NAME" "$COVERAGE_METRIC"
  upload_badge "$PROJECT_NAME" "$BRANCH_NAME" "$BADGE_COLOR_THRESHOLDS" "$COVERAGE_METRIC"
  if [[ "$HAS_BYPASS_LABEL" == "true" ]]; then
    echo 'Bypass label detected.'
    report_bypass "$COVERAGE_METRIC"
  else
    echo 'No bypass label detected.'
    fetch_coverage_metric "$PROJECT_NAME" "$BASE_BRANCH_NAME" "100"
    PREVIOUS_COVERAGE_METRIC=$FETCHED_COVERAGE_METRIC
    IS_COVERAGE_DECREASE=$(is_coverage_decrease "$COVERAGE_METRIC" "$PREVIOUS_COVERAGE_METRIC")
    if [[ "$IS_COVERAGE_DECREASE" == 'true' ]]; then
      echo 'Code coverage decrease detected.'
      report_failure "$COVERAGE_METRIC" "$PREVIOUS_COVERAGE_METRIC"
    else
      echo 'No code coverage decrease detected.'
      report_success "$COVERAGE_METRIC"
    fi
  fi
}