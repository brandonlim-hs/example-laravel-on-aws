#!/usr/bin/env bash

# Get environment variables from AWS System Manager Parameter Store
# And create .env from the environment variables.
aws ssm get-parameters-by-path \
  --path /Laravel/ \
  --region us-east-1 \
  --with-decryption \
  --output text \
  --query "Parameters[].[Name,Value]" |
  sed 's/^\/Laravel\///g' |
  sed 's/\t/=/g' \
    >.env
