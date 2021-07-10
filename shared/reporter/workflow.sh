#!/bin/bash

set_up_reporter() {
  echo 'set up reporter'
  echo "$@" > reporter_config.txt
}

tear_down_reporter() {
  echo 'tear down reporter'
  . "reporter_config.txt"
}

report_failure() {
  local COVERAGE_METRIC=$1
  local PREVIOUS_COVERAGE_METRIC=$2
  echo "Decrease in coverage detected. PR: $COVERAGE_METRIC vs Base: $PREVIOUS_COVERAGE_METRIC. Failing."
  tear_down_reporter
  exit 1
}

report_success() {
  local COVERAGE_METRIC=$1
  echo "No decrease in coverage detected. Coverage: $COVERAGE_METRIC. Passing."
  tear_down_reporter
  exit 0
}

report_bypass() {
  local COVERAGE_METRIC=$1
  echo "Possible decrease in coverage ignored. Coverage: $COVERAGE_METRIC. Bypassing."
  tear_down_reporter
  exit 0
}
