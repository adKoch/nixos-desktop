#!/usr/bin/env bash

# End-to-end test for sops secret generation and sealing validation
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_SCRIPT="$DIR/check_sealed.sh"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Starting SOPS sealing test..."

# 1. Generate a temporary age key for the test
export SOPS_AGE_KEY_FILE="$TEMP_DIR/keys.txt"
age-keygen -o "$SOPS_AGE_KEY_FILE" 2>/dev/null
PUBLIC_KEY=$(age-keygen -y "$SOPS_AGE_KEY_FILE")

# 2. Create a dummy secret file
SECRET_FILE="$TEMP_DIR/test-secret.yaml"
cat <<EOF > "$SECRET_FILE"
hello: world
EOF

# 3. Create a temporary .sops.yaml for the test
cat <<EOF > "$TEMP_DIR/.sops.yaml"
creation_rules:
  - path_regex: .*\.yaml$
    age: $PUBLIC_KEY
EOF

# 4. Encrypt the secret
echo "Encrypting secret..."
sops --config "$TEMP_DIR/.sops.yaml" -e -i "$SECRET_FILE"

# 5. Validate using the check_sealed.sh script
echo "Validating seal..."
if "$CHECK_SCRIPT" "$SECRET_FILE"; then
    echo "Test PASSED: Secret was successfully encrypted and validated."
else
    echo "Test FAILED: Validation script did not detect SOPS metadata."
    exit 1
fi
