#!/usr/bin/env bash

# Use environment variables with reasonable defaults
[ -f .env ] && source .env
PYTHON_REQ_PATH="${PYTHON_REQ_PATH:-src/shiny/requirements.txt}"

uv export --format requirements.txt --output-file "$PYTHON_REQ_PATH" --no-dev
