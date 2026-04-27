#!/usr/bin/env bash

# Idempotent script to check if a secret file is properly sealed (encrypted with sops)
# Usage: ./check_sealed.sh <path_to_secret_file>

FILE=$1

if [ -z "$FILE" ]; then
    echo "Usage: $0 <path_to_secret_file>"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found."
    exit 1
fi

# Check for sops metadata in the file
# Sops files typically contain a 'sops:' key in YAML/JSON
if grep -q "sops:" "$FILE"; then
    echo "Success: '$FILE' is properly sealed."
    exit 0
else
    echo "Failure: '$FILE' is NOT sealed (unencrypted)!"
    exit 1
fi
