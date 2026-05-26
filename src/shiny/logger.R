# Centralized logging configuration using the logger package

box::use(
  logger[
    log_threshold,
    INFO
  ],
)

box::use(
  reticulate[import_from_path],
)

LOG_LEVEL <- Sys.getenv("LOG_LEVEL", "INFO") # nolint: object_name_linter


#' Initialize logging for the application.
#'
#' Configures the logger package.
#' Should be called once at app startup.
init <- function() {
  # Set log level from env var (default INFO)
  level <- switch(
    LOG_LEVEL,
    "TRACE" = logger::TRACE,
    "DEBUG" = logger::DEBUG,
    "INFO" = INFO,
    "WARN" = logger::WARN,
    "ERROR" = logger::ERROR,
    "FATAL" = logger::FATAL,
    INFO
  )
  log_threshold(level)

  logger::log_info("Logger initialized at {LOG_LEVEL} level")
}
