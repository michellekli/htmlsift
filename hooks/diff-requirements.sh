#!/usr/bin/env bash

# Use environment variables with reasonable defaults
[ -f .env ] && source .env
PYTHON_REQ_PATH="${PYTHON_REQ_PATH:-src/shiny/requirements.txt}"

# Check if requirements.txt has changed
if git diff --name-only | grep -q "$PYTHON_REQ_PATH"; then
  echo "Error: requirements at $PYTHON_REQ_PATH has changed, stage to continue"
  exit 1
fi
