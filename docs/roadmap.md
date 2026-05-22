# htmlsift Roadmap

Phased implementation plan with each phase delivering a working, tested slice of the app.

> **Testing Strategy:** Every step below follows a concurrent testing approach, where backend (Python) components are tested primarily using `doctest` to keep documentation accurate, which are then integrated into the standard `unittest` suite (run via `python -m unittest`) to ensure formal test coverage. Note: Currently, frontend (R Shiny) components are not covered by this testing strategy.

---

## Phase 1: Foundation & Parsing

| Step | Task | Depends On |
| :--- | :--- | :--- |
| 1.1 | Build HTML input component | — |
| 1.2 | Configure and integrate HTML parsing library | 1.1 |
| 1.3 | Implement path identification & frequency ranking | 1.2 |

**Definition of done:**
- All unit tests pass
- HTML input accepts and validates raw HTML
- System utilizes HTML parsing library to generate hierarchical tree
- Path generator produces valid root-to-node paths with accurate frequency ranking

---

## Phase 2: Path Selection

| Step | Task | Depends On |
| :--- | :--- | :--- |
| 2.1 | Build Path List Zone UI | Phase 1 |
| 2.2 | Build Path Preview Modal | 2.1 |
| 2.3 | Implement path confirmation logic | 2.2 |

**Definition of done:**
- All unit tests pass
- Path List Zone renders scrollable top-ranked paths
- Selecting path triggers preview modal with 3-item sample
- Confirming path sets valid extraction rule

---

## Phase 3: Extraction & Linking

| Step | Task | Depends On |
| :--- | :--- | :--- |
| 3.1 | Implement text extraction logic | Phase 2 |
| 3.2 | Implement link detection & association | 3.1 |
| 3.3 | Build Extraction Zone UI | 3.1, 3.2 |

**Definition of done:**
- All unit tests pass
- Extraction Zone correctly displays text and associated links
- Link extraction accurately maps to corresponding text items

---

## Phase 4: Output & Formatting

| Step | Task | Depends On |
| :--- | :--- | :--- |
| 4.1 | Build export/download functionality | Phase 3 |
| 4.2 | Build UI controls for export | 4.1 |

**Definition of done:**
- All unit tests pass
- Export triggers download of correctly formatted JSON/CSV
- UI controls correctly switch between format options
