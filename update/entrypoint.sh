#!/bin/bash

# check if pull_request event
if [[ $GITHUB_EVENT_NAME != 'pull_request' ]]; then
  echo "This action is designed to be run in pull request context. Quitting."
  exit 1
fi

RUN_ID=$GITHUB_RUN_ID

BUCKET_NAME=$1
PROJECT_NAME=$2
BYPASS_LABEL=$3

# debug
# cat $GITHUB_EVENT_PATH
BASE_BRANCH_NAME=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.base.ref')
BRANCH_NAME=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.head.ref')
EVENT_TYPE=$(cat $GITHUB_EVENT_PATH | jq -r '.action')
HAS_BYPASS_LABEL=$(cat $GITHUB_EVENT_PATH | jq ".pull_request | any(.labels[]; .name == \"$BYPASS_LABEL\")")
IS_MERGED=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.merged')
PULL_REQUEST_URL=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.url')
STATUSES_URL=$(cat $GITHUB_EVENT_PATH | jq -r '.pull_request.statuses_url')

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
if [[ -z "$PROJECT_NAME" ]]; then
  echo "project-name input is required. Quitting."
  exit 1
fi
if [[ ! "$PROJECT_NAME" =~ ^[a-z\-]+$ ]]; then
  echo "project-name input is invalid. It should be a lower case kebab string (regex: [a-z\-]+). Quitting."
  exit 1
fi

# if event_type is closed
if [[ $EVENT_TYPE == 'closed' ]]; then
  if [[ $IS_MERGED == 'true' ]]; then
    # if pull_request is merged
    echo 'Pull request closed and merged. Overriding base branch data.'
    # rename coverage-metric file with base branch name
    COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt"
    COVERAGE_METRIC_S3_URI="s3://$BUCKET_NAME/$COVERAGE_METRIC_FILE_NAME"
    BASE_COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BASE_BRANCH_NAME.txt"
    BASE_COVERAGE_METRIC_S3_URI="s3://$BUCKET_NAME/$BASE_COVERAGE_METRIC_FILE_NAME"
    aws s3 mv $COVERAGE_METRIC_S3_URI $BASE_COVERAGE_METRIC_S3_URI --profile free-code-coverage
    # rename badge file with base branch name
    BADGE_FILE_NAME="badge-$PROJECT_NAME-$BRANCH_NAME.svg"
    BADGE_S3_URI="s3://$BUCKET_NAME/$BADGE_FILE_NAME"
    BASE_BADGE_FILE_NAME="badge-$PROJECT_NAME-$BASE_BRANCH_NAME.svg"
    BASE_BADGE_S3_URI="s3://$BUCKET_NAME/$BASE_BADGE_FILE_NAME"
    aws s3 mv $BADGE_S3_URI $BASE_BADGE_S3_URI --acl public-read --profile free-code-coverage
  else
    # if pull_request is not merged
    echo 'Pull request closed, but not merged. Cleaning related data.'
    # delete pull request coverage-metric file
    COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt"
    COVERAGE_METRIC_S3_URI="s3://$BUCKET_NAME/$COVERAGE_METRIC_FILE_NAME"
    aws s3 rm $COVERAGE_METRIC_S3_URI --profile free-code-coverage
    # delete pull request badge file
    BADGE_FILE_NAME="badge-$PROJECT_NAME-$BRANCH_NAME.svg"
    BADGE_S3_URI="s3://$BUCKET_NAME/$BADGE_FILE_NAME"
    aws s3 rm $BADGE_S3_URI --profile free-code-coverage
  fi
  # delete coverage report comment url file
  COVERAGE_REPORT_COMMENT_URL_FILE_NAME="coverage-report-comment-url-$PROJECT_NAME-$BRANCH_NAME.txt"
  COVERAGE_REPORT_COMMENT_URL_S3_URI="s3://$BUCKET_NAME/$COVERAGE_REPORT_COMMENT_URL_FILE_NAME"
  aws s3 rm $COVERAGE_REPORT_COMMENT_URL_S3_URI --profile free-code-coverage
# if event_type is labeled or unlabeled
elif [[ $EVENT_TYPE =~ ^(labeled|unlabeled)$ ]]; then
  # fetch last uploaded coverage metric or default to 0.0
  COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BRANCH_NAME.txt"
  COVERAGE_METRIC_S3_URI="s3://$BUCKET_NAME/$COVERAGE_METRIC_FILE_NAME"
  aws s3 ls $COVERAGE_METRIC_S3_URI &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo 'Coverage metric found.'
    aws s3 cp $COVERAGE_METRIC_S3_URI $COVERAGE_METRIC_FILE_NAME --profile free-code-coverage
    COVERAGE_METRIC=$(cat $COVERAGE_METRIC_FILE_NAME)
  else
    # if no coverage-metric found
    echo 'No coverage metric found. Defaulting to 0%.'
    # default to 0% coverage-metric value
    COVERAGE_METRIC=0
  fi
  if [[ $HAS_BYPASS_LABEL == "true" ]]; then
    # if request has bypass label
    echo 'Bypass label detected.'
    # add success check
    curl --request POST \
      --url $STATUSES_URL \
      --header "authorization: Bearer $GITHUB_TOKEN" \
      --header 'content-type: application/json' \
      --header 'accept: application/vnd.github.v3+json' \
      --data "{\"state\": \"success\",\"target_url\": \"${PULL_REQUEST_URL}/checks?check_run_id=${RUN_ID}\",\"description\": \"${COVERAGE_METRIC}% (BYPASS)\",\"context\": \"Code Coverage - ${PROJECT_NAME}\"}" \
      -o create_commit_status.txt &> /dev/null
  else
    # if no bypass label
    echo 'No bypass label detected.'
    # lookup coverage-metric file for base branch on the same project
    PREVIOUS_COVERAGE_METRIC_FILE_NAME="coverage-metric-$PROJECT_NAME-$BASE_BRANCH_NAME.txt"
    PREVIOUS_COVERAGE_METRIC_S3_URI="s3://$BUCKET_NAME/$PREVIOUS_COVERAGE_METRIC_FILE_NAME"
    aws s3 ls $PREVIOUS_COVERAGE_METRIC_S3_URI &> /dev/null
    if [[ $? -eq 0 ]]; then
      echo 'Previous coverage metric found.'
      aws s3 cp $PREVIOUS_COVERAGE_METRIC_S3_URI $PREVIOUS_COVERAGE_METRIC_FILE_NAME --profile free-code-coverage
      PREVIOUS_COVERAGE_METRIC=$(cat $PREVIOUS_COVERAGE_METRIC_FILE_NAME)
    else
      # if no coverage-metric found
      echo 'No previous coverage metric found. Defaulting to 100%.'
      # default to 100% coverage-metric value
      PREVIOUS_COVERAGE_METRIC=100
    fi
    # compare base coverage-metric with provided coverage-metric
    if (( $(echo "$COVERAGE_METRIC < $PREVIOUS_COVERAGE_METRIC" | bc -l) )); then
      # if provided < base
      echo 'Code coverage decrease detected.'
      # add failure check
      curl --request POST \
        --url $STATUSES_URL \
        --header "authorization: Bearer $GITHUB_TOKEN" \
        --header 'content-type: application/json' \
        --header 'accept: application/vnd.github.v3+json' \
        --data "{\"state\": \"failure\",\"target_url\": \"${PULL_REQUEST_URL}/checks?check_run_id=${RUN_ID}\",\"description\": \"PR: ${COVERAGE_METRIC}% vs Base: ${PREVIOUS_COVERAGE_METRIC}%\",\"context\": \"Code Coverage - ${PROJECT_NAME}\"}" \
        -o create_commit_status.txt &> /dev/null
    else
      # if provided >= base
      echo 'No code coverage decrease detected.'
      # add success check
      curl --request POST \
        --url $STATUSES_URL \
        --header "authorization: Bearer $GITHUB_TOKEN" \
        --header 'content-type: application/json' \
        --header 'accept: application/vnd.github.v3+json' \
        --data "{\"state\": \"success\",\"target_url\": \"${PULL_REQUEST_URL}/checks?check_run_id=${RUN_ID}\",\"description\": \"${COVERAGE_METRIC}%\",\"context\": \"Code Coverage - ${PROJECT_NAME}\"}" \
        -o create_commit_status.txt &> /dev/null
    fi
  fi
else
  echo 'This action is designed to be run with pull_request event types: unlabeled, labeled, and closed. Quitting.'
  exit 1
fi

# clear AWS credentials
aws configure --profile free-code-coverage <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
