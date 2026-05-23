#!/usr/bin/env Rscript

# Use packages set up by renv for this project
renv::load()

# Get files to be linted (passed by pre-commit)
files <- commandArgs(trailingOnly = TRUE)

for (file in files) {
    lints <- lintr::lint(file)
    if (length(lints) > 0) {
        print(lints)
        stop("Lints found for file")
    }
}
