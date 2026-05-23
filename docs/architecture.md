# htmlsift Architecture

## Scaffolding Decisions

| Concern | Choice | Rationale |
| :--- | :--- | :--- |
| **Dependencies (Python)** | `uv` | Modern, fast dependency management and environment creation |
| **Dependencies (R)** | `renv` | Reproducible environment management for R |
| **Linting & Formatting** | `pre-commit` | Automated code quality and consistency checks |
| **CI/CD** | GitHub Actions | Automated build, test, and deployment pipelines |\
| **Backend Processing** | Python (`reticulate`) | Utilizes robust libraries for HTML/DOM manipulation |
| **Testing (Python)** | `doctest` + `unittest` | Validates Python backend code functionality (`doctest`) and ensures formal coverage (`unittest`). Note: Frontend (R Shiny) testing is currently out of scope. |
| **Code Coverage** | `Codecov` | Provides visibility into test efficacy and automates coverage tracking in CI/CD pipelines. |
| **Data Extraction** | lxml + pandas | Chosen for HTML parsing speed (via lxml) and efficient data manipulation (via pandas) |
| **Frontend Framework** | R Shiny | Enables interactive UI with minimal boilerplate |
| **Styling** | `bslib` | Provides modern, Bootstrap-based UI components |
| **Concurrency** | `future` + `promises` (R) | Maintains UI responsiveness during heavy backend tasks |
| **Security** | `nh3` | Sanitizes HTML input before processing |
| **Deployment** | Posit Connect Cloud | Managed hosting for R/Python applications |

## Project Scaffolding Sequence

1. Configure dependency management with uv, renv.
2. Create boilerplate R Shiny app.
3. Test Python integration in R Shiny app with reticulate.
4. Establish quality assurance with pre-commit.
5. Deploy R Shiny app to Posit Connect Cloud.
6. Setup CI/CD with GitHub Actions, including automated test coverage reporting via Codecov.
7. Write README.

> Design decisions are documented in [`design.md`](./design.md).
