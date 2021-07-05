#!/bin/bash

# check if pull_request event
if [[ $GITHUB_EVENT_NAME != 'pull_request' ]]; then
  echo "This action is designed to be run in pull request context. Quitting."
  exit 1
fi

# debug
# cat $GITHUB_EVENT_PATH
BASE_BRANCH_NAME=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.base.ref')
BRANCH_NAME=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.head.ref')
COMMIT_SHA=$GITHUB_SHA

# check if github token is set
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "GITHUB_TOKEN env variable is not set. Quitting."
  exit 1
fi

# check if aws credentials are set
if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "AWS_ACCESS_KEY_ID env variable is not set. Quitting."
  exit 1
fi
if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "AWS_SECRET_ACCESS_KEY env variable is not set. Quitting."
  exit 1
fi
if [[ -z "$AWS_REGION" ]]; then
  AWS_REGION="us-east-1"
fi
# create a dedicated aws profile to avoid conflicts with other actions
aws configure --profile free-code-coverage <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

# check if bucket-name is provided and non-empty
BUCKET_NAME=$1
if [[ -z "$BUCKET_NAME" ]]; then
  echo "bucket-name input is required. Quitting."
  exit 1
fi
# check if bucket exists and reachable (AWS) (aws s3 ls $BUCKET_NAME)
aws s3 ls $BUCKET_NAME --profile free-code-coverage &> /dev/null
if [[ $? -ne 0 ]]; then
  echo "Unreachable S3 bucket. Quitting."
  exit 1
fi
# check if project-name is provided and non-empty and lower kebab case (regex: [a-z\-]+)
PROJECT_NAME=$2
if [[ -z "$PROJECT_NAME" ]]; then
  echo "project-name input is required. Quitting."
  exit 1
fi
if [[ ! "$PROJECT_NAME" =~ ^[a-z\-]+$ ]]; then
  echo "project-name input is invalid. It should be a lower case kebab string (regex: [a-z\-]+). Quitting."
  exit 1
fi
# check if coverage-metric is provided and number between 0 and 100
COVERAGE_METRIC=$3
COVERAGE_METRIC_REGEX='^(100(\.0)?|\d{1,2}(\.\d)?)$'
if [[ -z "$COVERAGE_METRIC" ]]; then
  echo "coverage-metric input is required. Quitting."
  exit 1
fi
if [[ ! "$COVERAGE_METRIC" =~ $COVERAGE_METRIC_REGEX ]]; then
  echo "coverage-metric must be a number between 0 and 100 with at most one digit. Quitting."
  exit 1
fi
# check if badge-color-thresholds are provided
BADGE_COLOR_THRESHOLDS=$5
if [[ -z "$BADGE_COLOR_THRESHOLDS" ]]; then
  BADGE_COLOR_THRESHOLDS="50,60,70,80,90"
else
  # check that it is a strictly increasing comma-separated list of 5 numbers between 0 and 100
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
  SORTED=($(echo "${THRESHOLDS[*]}" | tr " " "\n" | sort))
  DIFF=$(diff <(printf "%s\n" "${THRESHOLDS[@]}") <(printf "%s\n" "${SORTED[@]}"))
  if [[ -n "$DIFF" ]]; then
    echo "badge-color-thresholds must be a comma-separated list of 5 strictly increasing numbers between 0 and 100 with at most one digit. Quitting."
    exit 1
  fi
fi

# if push event_type - labeled, unlabeled, opened, reopened, and synchronize
EVENT_TYPE=$(cat $GITHUB_EVENT_PATH | jq -r '.action')
if [[ $EVENT_TYPE =~ ^(labeled|unlabeled|opened|reopened|synchronize)$ ]]; then
  # if coverage-report provided and non-empty
  COVERAGE_REPORT=$4
  if [[ -n "$COVERAGE_REPORT" ]]; then
    COVERAGE_REPORT_COMMENT_URL_FILE_NAME="delete-coverage-report-comment-url-$PROJECT_NAME-$BRANCH_NAME.txt"
    COVERAGE_REPORT_COMMENT_URL_S3_URI="s3://$BUCKET_NAME/$COVERAGE_REPORT_COMMENT_URL_FILE_NAME"
    # remove any free-code-coverage bot comments on pull request
    aws s3 ls $COVERAGE_REPORT_COMMENT_URL_S3_URI &> /dev/null
    if [[ $? -eq 0 ]]; then
      echo "Deleting previous coverage report comment."
      aws s3 cp $COVERAGE_REPORT_COMMENT_URL_S3_URI $COVERAGE_REPORT_COMMENT_URL_FILE_NAME --profile free-code-coverage
      DELETE_COVERAGE_REPORT_COMMENT_URL=$(cat $COVERAGE_REPORT_COMMENT_URL_FILE_NAME)
      curl --request DELETE \
        --url $DELETE_COVERAGE_REPORT_COMMENT_URL \
        --header "authorization: Bearer $GITHUB_TOKEN" \
        --header 'content-type: application/json' \
        --header 'accept: application/vnd.github.v3+json' \
        -o delete_coverage_report_comment.txt &> /dev/null
    else
      echo "No previous coverage report comment to delete."
    fi
    # comment pull request with provided coverage-report
    CREATE_COVERAGE_REPORT_COMMENT_URL=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.comments_url')
    curl --request POST \
      --url $CREATE_COVERAGE_REPORT_COMMENT_URL \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      --header 'content-type: application/json' \
      --header 'accept: application/vnd.github.v3+json' \
      --data "{\"body\": \"$COVERAGE_REPORT\"}" \
      -o create_coverage_report_comment.txt &> /dev/null
    # persist comment id
    cat create_coverage_report_comment.txt | jq -r '.url' > $COVERAGE_REPORT_COMMENT_URL_FILE_NAME
    aws s3 cp $COVERAGE_REPORT_COMMENT_URL_FILE_NAME $COVERAGE_REPORT_COMMENT_URL_S3_URI --profile free-code-coverage
  fi
  # upload coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt file containing provided coverage-metric value
  COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt"
  COVERAGE_METRIC_S3_URI="s3://$BUCKET_NAME/$COVERAGE_METRIC_FILE_NAME"
  echo "$COVERAGE_METRIC" > $COVERAGE_METRIC_FILE_NAME
  aws s3 cp $COVERAGE_METRIC_FILE_NAME $COVERAGE_METRIC_S3_URI --profile free-code-coverage
  # compute badge color from coverage-metric
    # Colors
      # brightgreen [100-90[
      # green [90-80[
      # yellowgreen [80-70[
      # yellow [70-60[
      # orange [60-50[
      # red [50-0]
  BADGE_COLORS=(red orange yellow yellowgreen green brightgreen)
  COLOR_INDEX=0
  for i in "${!THRESHOLDS[@]}"; do
    if (( $(echo "$COVERAGE_METRIC > ${THRESHOLDS[$i]}" | bc -l) )); then
      COLOR_INDEX=$((i+1))
    fi
  done
  BADGE_COLOR=${BADGE_COLORS[$COLOR_INDEX]}
  # upload badge to S3 bucket and make it public (filename: "badge-$PROJECT_NAME-$BRANCH_NAME.svg")
  BADGE_FILE_NAME="badge-$PROJECT_NAME-$BRANCH_NAME.svg"
  BADGE_S3_URI="s3://$BUCKET_NAME/$BADGE_FILE_NAME"
  PROJECT_NAME_PARTS=(${PORJECT_NAME//-/ })
  PASCAL_CASE_PROJECT_NAME=$(printf %s "${PROJECT_NAME_PARTS[@]^}")
  curl \
    "https://img.shields.io/badge/coverage%20$PASCAL_CASE_PROJECT_NAME-$COVERAGE_METRIC%25-$BADGE_COLOR" \
    -o $BADGE_FILE_NAME &> /dev/null
  aws s3 cp $BADGE_FILE_NAME $BADGE_S3_URI --acl public-read --cache-control no-cache --profile free-code-coverage
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
fi
# TODO: if push event_type is closed
  # TODO: if pull_request is merged
    # TODO: rename coverage-metric file with base branch name
    # TODO: rename badge file with base branch name
  # TODO: otherwise
    # TODO: delete pull request coverage-metric file
    # TODO: delete pull request badge file

# clear AWS credentials
aws configure --profile free-code-coverage <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
