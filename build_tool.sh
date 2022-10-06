#!/bin/bash

set -o noglob
set -e

currentDir=$(dirname "$0")
if [[ "$currentDir" == "." ]]; then
    currentDir=$(pwd)
fi
cd "${currentDir}"

# define variables
AVAILABLE_OPTION=true
export HTTP_PROXY=
export HTTPS_PROXY=
export GOARCH=amd64
OUTPUT_BIN=retrieve-vault-token


case $1 in
  windows | window)
    printf "Starting build for window..."
    export GOOS=windows
    export OUTPUT_BIN=retrieve-vault-token.exe
    ;;
  macos)
    printf "Starting build for macos..."
    export GOOS=darwin
    ;;
  linux)
    printf "Starting build for linux..."
    export GOOS=linux
    ;;
  *)
    go version
    printf "Unsupported GOOS/GOARCH. Only available GOOS/GOARCH below:
✓ darwin (386|amd64|arm|arm64)
✓ linux (386|amd64|arm|arm64)
✓ windows (386|amd64)

"
    AVAILABLE_OPTION=false
    ;;
esac

if $AVAILABLE_OPTION; then
  go build -o ${OUTPUT_BIN} .
  printf "OK.\n"
fi


