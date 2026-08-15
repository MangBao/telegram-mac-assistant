#!/usr/bin/env bash

# Lightweight validation for bootstrap foundation

echo "Running tests..."

# 1. Test profile existence
if [ ! -f "profiles/company-mac-mini/profile.yaml" ]; then
    echo "FAIL: company-mac-mini profile missing"
    exit 1
fi
if [ ! -f "profiles/personal-mac/profile.yaml" ]; then
    echo "FAIL: personal-mac profile missing"
    exit 1
fi
echo "PASS: Profiles exist."

# 2. Test idempotency (dry run logic / actual run logic)
# We can just run bootstrap again to see if it crashes.
./bootstrap.sh company-mac-mini >/dev/null
if [ $? -ne 0 ]; then
    echo "FAIL: bootstrap.sh is not idempotent or failed."
    exit 1
fi
echo "PASS: Bootstrap script executes successfully."

# 3. Check workspace structure
WORKSPACE="$HOME/AI-Workspace"
for dir in projects documents downloads scratch; do
    if [ ! -d "$WORKSPACE/$dir" ]; then
        echo "FAIL: Workspace directory $dir missing."
        exit 1
    fi
done
echo "PASS: Workspace directories exist."

# 4. Check doctor script runs
./scripts/doctor.sh >/dev/null
if [ $? -ne 0 ]; then
    echo "FAIL: doctor.sh failed to run."
    exit 1
fi
echo "PASS: doctor.sh executes successfully."

# 5. Check gitignore contents
if ! grep -q "credentials/" .gitignore; then
    echo "FAIL: .gitignore missing credentials ignore."
    exit 1
fi
echo "PASS: .gitignore rules present."

echo "All tests passed successfully!"
