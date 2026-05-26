# This file is the entry point for the R Shiny app.
# It contains configuration required for the entire app
# and should contain the bare minimum needed to start the app.

# Show traceback on error and line numbers
options(error = traceback, show.error.locations = TRUE)

# Must be run to update changes to local modules
box::purge_cache()

# Load function for running shiny app
box::use(
  shiny[shinyApp],
)

box::use(
  ./logger,
)

# Initialize logging
logger$init()

# Load initial route
box::use(
  routes/home
)

# Run the application
shinyApp(ui = home$ui, server = home$server)
