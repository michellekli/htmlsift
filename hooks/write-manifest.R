#!/usr/bin/env Rscript

# Use packages set up by renv for this project
renv::load()

# Get the app path from environment variable
# default to "src/shiny"
if (file.exists(".env")) {
  dotenv::load_dot_env(".env")
}

app_path <- Sys.getenv("SHINY_APP_PATH", unset = "src/shiny")
# Use forceGeneratePythonEnvironment when Python dependencies are out-dated,
# otherwise it will always change the checksum in manifest.json
#rsconnect::writeManifest(appDir = app_path, forceGeneratePythonEnvironment = TRUE)
rsconnect::writeManifest(appDir = app_path)
