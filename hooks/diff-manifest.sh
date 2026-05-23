#!/usr/bin/env bash

# Use the environment variable MANIFEST_PATH
# defaulting to src/shiny/manifest.json if unset
[ -f .env ] && source .env
MANIFEST_PATH="${MANIFEST_PATH:-src/shiny/manifest.json}"

# Check if manifest.json has changed
if git diff --name-only | grep -q "$MANIFEST_PATH"; then
  echo "Error: manifest at $MANIFEST_PATH has changed, stage to continue"
  exit 1
fi
