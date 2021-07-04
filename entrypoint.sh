#!/bin/sh

# TODO: check if pull_request event
# TODO: if push event_type - labeled, unlabeled, opened, reopened, and synchronize
  # TODO: check if bucket-name is provided and non-empty
  # TODO: check if bucket exists and reachable (AWS)
  # TODO: check if project-name is provided and non-empty and lower kebab case (regex: [a-z\-]+)
  # TODO: check if coverage-metric is provided and number between 0 and 100
  # TODO: check if badge-color-thresholds are provided
    # TODO: check that it is a strictly increasing comma-separated list of 5 numbers between 0 and 100
  # TODO: if coverage-report provided and non-empty
    # TODO: remove any free-code-coverage bot comments on pull request
    # TODO: comment pull request with provided coverage-report
  # TODO: upload coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt file containing provided coverage-metric value
  # TODO: compute badge color from coverage-metric
  # TODO: upload badge to S3 bucket and make it public (filename: "$PROJECT_NAME-$BRANCH_NAME-badge.svg")
    # Colors
      # brightgreen [100-90[
      # green [90-80[
      # yellowgreen [80-70[
      # yellow [70-60[
      # orange [60-50[
      # red [50-0]
    # https://img.shields.io/badge/coverage%20project%20name-100%25-brightgreen
  # TODO: if pull request have bypass label
    # TODO: add success check
  # TODO: if no bypass label
    # TODO: get base branch pull request
    # TODO: lookup coverage-metric file for base branch on the same project
    # TODO: if no coverage-metric found
      # TODO: default to 100% coverage-metric value
    # TODO: compare base coverage-metric with provided coverage-metric
    # TODO: if provided < base
      # TODO: add failure check
    # TODO: otherwise
      # TODO: add success check
# TODO: if push event_type is closed
  # TODO: if pull_request is merged
    # TODO: rename coverage-metric file with base branch name
    # TODO: rename badge file with base branch name
  # TODO: otherwise
    # TODO: delete pull request coverage-metric file
    # TODO: delete pull request badge file
