[![codecov](https://codecov.io/gh/michellekli/htmlsift/graph/badge.svg?token=69SNIHGCNI)](https://codecov.io/gh/michellekli/htmlsift)

# htmlsift

Paste your HTML. Visualize the content. Download structured data.

Htmlsift is an interactive web interface designed to extract structured data from HTML documents without requiring any programming knowledge. It visualizes the DOM, allowing you to select elements for extraction and export structured data.

## Quick start

Visit [htmlsift](https://michellekli-htmlsift.share.connect.posit.cloud) to start using it immediately.

## How it works

1. **Input**: Paste your HTML document into the text area.
2. **Explore**: View the paths through the document.
3. **Select**: Choose the path containing content for extraction.
4. **Export**: Download your data as JSON or CSV.

## Development

**Prerequisites:** R and Python.

Key scaffolding decisions are documented in [`docs/architecture.md`](docs/architecture.md).

### Commands

| Command | Description |
| :--- | :--- |
| `shiny::runApp("src/shiny")` | Start the Shiny development server |
| `uv run python -m pytest` | Run Python unit tests |

### Project conventions

- **Dependency management:** R dependencies are managed via `renv`; Python dependencies via `uv`.
- **Testing:** Python unit tests use `doctest`; coverage reports are generated using `pytest`. Frontend (R Shiny) testing is currently out of scope.

## License

[Apache License 2.0](LICENSE)
