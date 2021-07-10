#!/bin/bash

set_up_persistence() {
  echo 'set up persistence'
  local GITHUB_TOKEN=$1
  local GITHUB_REPO=$2
  validate_github_token "$GITHUB_TOKEN"
  validate_github_repo "$GITHUB_TOKEN" "$GITHUB_REPO"
  echo "local GITHUB_TOKEN=\"$GITHUB_TOKEN\"" > persistence_config.txt
  echo "local GITHUB_REPO=\"$GITHUB_REPO\"" >> persistence_config.txt
}

validate_github_token() {
  local GITHUB_TOKEN=$1
  if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "GITHUB_TOKEN env variable is not set. Quitting."
    exit 1
  fi
}

validate_github_repo() {
  local GITHUB_TOKEN=$1
  local GITHUB_REPO=$2
  if [[ -z "$GITHUB_REPO" ]]; then
    echo "github-repo input is required. Quitting."
    exit 1
  fi
  if [[ ! "$GITHUB_REPO" =~ ^([a-z]|[A-Z]|\-|\_)+/([a-z]|[A-Z]|\-|\_)+$ ]]; then
    echo "github-repo must follow {owner}/{repo} format. Quitting."
    exit 1
  fi
  local IS_REACHABLE
  IS_REACHABLE=$(is_reachable_repo "$GITHUB_TOKEN" "$GITHUB_REPO")
  if [[ "$IS_REACHABLE" == 'false' ]]; then
    echo "Repository non reachable. Quitting."
    exit 1
  fi
  local IS_PUBLIC
  IS_PUBLIC=$(is_public_repo "$GITHUB_TOKEN" "$GITHUB_REPO")
  if [[ "$IS_PUBLIC" == 'false' ]]; then
    echo "Repository must be public. Quitting."
    exit 1
  fi
}

is_reachable_repo() {
  local GITHUB_TOKEN=$1
  local GITHUB_REPO=$2
  curl \
    --header "accept: application/vnd.github.v3+json" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --url "https://api.github.com/repos/$GITHUB_REPO" \
    -o "get_repo.json" &> /dev/null
  local IS_REACHABLE
  jq -e '.id' get_repo.json
  if [[ $? -eq 0 ]]; then
    echo 'true'
  else
    echo 'false'
  fi
}

is_public_repo() {
  local GITHUB_TOKEN=$1
  local GITHUB_REPO=$2
  curl \
    --header "accept: application/vnd.github.v3+json" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --url "https://api.github.com/repos/$GITHUB_REPO" \
    -o "get_repo.json" &> /dev/null
  local IS_PRIVATE
  IS_PRIVATE=$(jq -r '.private' get_repo.json)
  if [[ "$IS_PRIVATE" == 'false' ]]; then
    echo 'true'
  else
    echo 'false'
  fi
}

tear_down_persistence() {
  echo 'tear down persistence'
  rm persistence_config.txt
}

get_file_url() {
  . "persistence_config.txt"
  local FILE_NAME=$1
  echo "https://api.github.com/repos/$GITHUB_REPO/contents/$FILE_NAME"
}

get_file_sha() {
  . "persistence_config.txt"
  local FILE_NAME=$1
  curl \
    --header "accept: application/vnd.github.v3+json" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --url "$(get_file_url "$FILE_NAME")" \
    -o "file.json" &> /dev/null
  jq -r '.sha' file.json
}

has_file() {
  local FILE_NAME=$1
  local SHA
  SHA=$(get_file_sha "$FILE_NAME")
  if [[ "$SHA" != 'null' ]]; then
    echo 'true'
  else
    echo 'false'
  fi
}

get_file() {
  . "persistence_config.txt"
  local FILE_NAME=$1
  curl \
    --header "accept: application/vnd.github.v3+json" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --url "$(get_file_url "$FILE_NAME")" \
    -o "get_file.json" &> /dev/null
  jq -r '.content' get_file.json | base64 -d > "$FILE_NAME"
}

set_file() {
  . "persistence_config.txt"
  local FILE_NAME=$1
  delete_file "$FILE_NAME"
  curl --request PUT \
    --header "accept: application/vnd.github.v3+json" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --header "content-Type: application/json; charset=utf-8" \
    --url "$(get_file_url "$FILE_NAME")" \
    --data "{\"message\": \"free-code-coverage set_file\", \"content\": \"$(base64 "$FILE_NAME" | tr -d '\r\n')\" }" \
    -o "set_file.json" &> /dev/null
}

set_publicly_readable_file() {
  local FILE_NAME=$1
  set_file "$FILE_NAME"
}

delete_file() {
  . "persistence_config.txt"
  local FILE_NAME=$1
  local SHA
  SHA=$(get_file_sha "$FILE_NAME")
  curl --request DELETE \
    --header "accept: application/vnd.github.v3+json" \
    --header "authorization: Bearer $GITHUB_TOKEN" \
    --header "content-Type: application/json; charset=utf-8" \
    --url "$(get_file_url "$FILE_NAME")" \
    --data "{\"message\": \"free-code-coverage delete_file\", \"sha\": \"$SHA\" }" \
    -o "delete_file.json" &> /dev/null
}

rename_file() {
  local FROM_FILE=$1
  local TO_FILE=$2
  get_file "$FROM_FILE"
  mv "$FROM_FILE" "$TO_FILE"
  set_file "$TO_FILE"
  delete_file "$FROM_FILE"
}

rename_publicly_readable_file() {
  local FROM_FILE=$1
  local TO_FILE=$2
  rename_file "$FROM_FILE" "$TO_FILE"
}

