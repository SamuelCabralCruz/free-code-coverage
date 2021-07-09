#!/bin/bash

aws s3 rm s3://free-code-coverage/ --recursive --include "*"
echo "50.0" > coverage-metric-failure-main.txt
echo "50.0" > coverage-metric-success-main.txt
aws s3 cp coverage-metric-failure-main.txt s3://free-code-coverage/coverage-metric-failure-main.txt
aws s3 cp coverage-metric-success-main.txt s3://free-code-coverage/coverage-metric-success-main.txt
rm coverage-metric-failure-main.txt
rm coverage-metric-success-main.txt
