#!/usr/bin/env bash

if [[ "$(Rscript -e 'renv::status()')" != "No issues found -- the project is in a consistent state." ]]; then
    echo "check renv issues with renv::status(), update lockfile with renv::snapshot()"
    exit 1
fi
