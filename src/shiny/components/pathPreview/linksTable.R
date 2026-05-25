# Displays a DT datatable of links or a "No links found" message
box::use(
  bslib[...],
  shiny[...],
)

#' Links table module UI
#'
#' @param id Module namespace identifier.
#' @return A uiOutput placeholder for the links table or no-links message.
#' @export
ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("links_container"))
}

#' Links table module server
#'
#' Renders a DT data table of links or a "No links found" placeholder.
#'
#' @param id Module namespace identifier.
#' @param links_reactive A reactive vector or list of link hrefs.
#' @export
server <- function(id, links_reactive) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ----------------------
    # --- REACTIVE STATE ---
    # ----------------------

    # ----------------------
    # --- EVENT HANDLING ---
    # ----------------------

    # Handle change in links
    # Create container for links
    output$links_container <- renderUI({
      links <- links_reactive()

      if (length(links) > 0) {
        DT::DTOutput(ns("links_dt"))
      } else {
        div(
          style = "padding: 10px; color: #6c757d; font-style: italic;",
          "No links found"
        )
      }
    }) |> bindEvent(links_reactive())

    # Handle change in links
    # Create links display
    output$links_dt <- DT::renderDT({
      req(length(links_reactive()) > 0)
      links <- links_reactive()

      tryCatch({
        validate(
          need(is.list(links) || is.vector(links),
               "Links data must be a list or vector.")
        )
        links_df <- data.frame(
          href = unlist(links)
        )

        DT::datatable(
          links_df,
          options = list(
            pageLength = 3,
            scrollY = "100px",
            scrollCollapse = TRUE,
            paging = FALSE,
            searching = FALSE,
            info = FALSE
          ),
          rownames = FALSE,
          selection = "none"
        )
      }, error = function(e) {
        DT::datatable(
          data.frame(href = paste("Unable to load links:", e$message)),
          options = list(
            scrollY = "100px",
            scrollCollapse = TRUE,
            paging = FALSE,
            searching = FALSE,
            info = FALSE
          ),
          rownames = FALSE,
          selection = "none"
        )
      })
    }) |> bindEvent(links_reactive())
  })
}
