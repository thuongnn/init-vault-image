#!/bin/sh

TEMPLATE=$1

printf "[DEBUG] VAULT_ADDR=%s\n\n" "$VAULT_ADDR"

printf "Starting to retrieve Vault token with [Service Account Token]..."
export VAULT_TOKEN=$(retrieve-vault-token)
printf "OK.\n"

RESULT=$?
if [ $RESULT -eq 0 ]; then
  printf "Starting to render file with Vault Template..."
  consul-template -template "${TEMPLATE}" -once
  printf "OK.\n"
  printf "Done.\n"
fi


