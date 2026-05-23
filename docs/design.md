# htmlsift Design Document

## 1. Introduction

### 1.1 Purpose
The purpose of this project is to provide an interactive web interface for users to extract, visualize, and export specific items from a provided HTML document. The tool assists users in mapping complex hierarchical HTML structures to specific text content by visualizing navigation paths and allowing dynamic selection of extracted data.

### 1.2 Target Audience
People who require specific text extraction based on document structure.

### 1.3 Goals
*   **Clarity:** Visually demonstrate the relationship between HTML path nodes and resulting text data.

## 2. Scope

### 2.1 In Scope
*   Acceptance of raw HTML string content via user input.
*   Parsing and analysis of the HTML document's tree structure.
*   Generation and display of hierarchical path suggestions based on frequency.
*   Extraction logic based on user-defined paths.
*   Automated extraction of hypertext references (links) associated with identified text.
*   Presentation of extracted item lists.
*   Data export functionality in JSON and CSV formats.

### 2.2 Out of Scope
*   Real-time live website scraping (only provided HTML is processed).
*   Modification of the extracted content.
*   Integration with external user-accessible databases or third-party cloud storage services. (Note: Infrastructure hosting environments, such as Posit Connect Cloud, are permitted.)

## 3. Functional Requirements

### 3.1 HTML Input
1.  **Input Acceptance:** The interface shall accept HTML content provided by the user through a text input mechanism.
2.  **Structure Parsing:** The system shall parse the input HTML into a hierarchical tree structure.
3.  **Path Identification:** The system shall generate all valid root-to-node paths within the HTML structure.
4.  **Frequency Ranking:** Identified paths shall be sorted in descending order based on their occurrence frequency in the input HTML.

### 3.2 Path Selection
1.  **Path Selection View:** The interface shall display a scrollable list of top-ranked root-to-node paths.
2.  **Path Preview:** After selecting a path entry, the system shall display a modal containing a preview of the first three items that would be extracted if this path were applied. The modal shall include a mechanism for the user to confirm the selection of this path for extraction, or cancel the selection.
3.  **Path Confirmation:** Upon user confirmation of a path, the system shall store this path definition as the active extraction rule.

### 3.3 Text Extraction
1.  **Extraction Execution:** Based on the active path definition, the system shall locate all matching elements in the document and display their text in the dedicated side panel for viewing.

### 3.4 Link Extraction
1.  **Automatic Detection:** During the extraction process (Section 3.3), the system shall automatically identify all hypertext references (links) contained within the matching elements.
2.  **Data Association:** These links shall be associated with the corresponding text item in the output.

### 3.5 Output & Formatting
1.  **Format Options:** Users shall be able to choose between JSON or CSV output formats for the extracted data.
2.  **Download:** Upon final selection, the system shall generate and initiate download of the data file in the chosen format.

## 4. User Interface Layout & Flow

### 4.1 Primary Layout
The application shall utilize a dashboard layout containing three main interactive zones:
1.  **Configuration Zone (Left):** Contains the HTML input mechanism.
2.  **Path List Zone (Center):** A scrollable container displaying the root-to-node paths and allowing individual selection.
3.  **Extraction Zone (Right):** A side panel that populates with all extracted data only after a path has been successfully confirmed via the modal. This zone contains the interface controls for selecting the output format (JSON/CSV) and initiating the data download.

### 4.2 Workflow Steps
**Step 1: Setup**
1.  User enters or pastes HTML content into the input field.
2.  System processes and generates the "Path List Zone."

**Step 2: Path Selection**
1.  User reviews the sorted list of paths.
2.  User selects a "Path Rule" to initiate the preview modal.
3.  User confirms selection of the "Path Rule" within the modal.

**Step 3: Extraction & Export**
1.  System populates the "Extraction Zone" with all text from the confirmed "Path Rule", including any associated links.

**Step 4: Export**
1.  In the Extraction Zone, the user selects the desired output format (JSON/CSV) and triggers the download action.

## 5. Data Structures & Definitions

### 5.1 Input Schema (User Perspective)
*   **Input:** Raw HTML string text provided by the user.
*   **Output Format:** CSV or JSON file.

### 5.2 Output Schema (System Perspective)
*   **Path Object:**
    *   `path`: String representing the root-to-node path, ex. div/div/p.
    *   `frequency`: Count of matches found in the input document.
*   **Text Object:**
    *   `text`: The extracted text content.
    *   `links`: Array of hypertext references within text.
*   **Dataset Object:**
    *   `type`: JSON Array or CSV String.
    *   `content`: The structured data ready for download.

### 5.3 File Output Definitions
*   **JSON:** Object containing array with items containing `text` and `links`.
*   **CSV:** Tabular representation with columns for `text` and `links`.

## 6. Non-Functional Requirements

### 6.1 Usability
*   **Scrollability:** The item list must remain scrollable without reloading the page.

### 6.2 Reliability
*   **Error Handling:** The system shall provide clear error messages for malformed HTML inputs.
*   **Data Integrity:** The extracted data in the JSON/CSV output must be from the HTML input provided by the user.

### 6.3 Security
*   **Input Sanitization:** The HTML content shall be sanitized to prevent any execution of malicious scripts before parsing.

## 7. Glossary

*   **Path:** A sequence of HTML nodes starting from the root down to a node.
*   **Item:** A specific data entity extracted from the HTML structure based on the selected path.
*   **Output:** The aggregated dataset resulting from applying a path rule to the entire document.
