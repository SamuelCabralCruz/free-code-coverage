on_pull_request_closed() {
  local PROJECT_NAME=$1
  local BRANCH_NAME=$2
  local BASE_BRANCH_NAME=$3
  local IS_MERGED=$4
  if [[ $IS_MERGED == 'true' ]]; then
    echo 'Pull request closed and merged. Overriding base branch data.'
    override_coverage_file "$PROJECT_NAME" "$BRANCH_NAME" "$BASE_BRANCH_NAME"
    override_badge_file "$PROJECT_NAME" "$BRANCH_NAME" "$BASE_BRANCH_NAME"
  else
    echo 'Pull request closed, but not merged. Cleaning related data.'
    delete_file "coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt"
    delete_file "badge-$PROJECT_NAME-$BRANCH_NAME.svg"
  fi
  delete_file "coverage-report-comment-url-$PROJECT_NAME-$BRANCH_NAME.txt"
}

on_pull_request_labeled() {
  local PROJECT_NAME=$1
  local BRANCH_NAME=$2
  local BASE_BRANCH_NAME=$3
  local HAS_BYPASS_LABEL=$4
  fetch_coverage_metric "$PROJECT_NAME" "$BRANCH_NAME" "0"
  COVERAGE_METRIC=$FETCHED_COVERAGE_METRIC
  if [[ $HAS_BYPASS_LABEL == "true" ]]; then
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
