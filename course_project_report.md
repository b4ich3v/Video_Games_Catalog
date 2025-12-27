# Sofia University “St. Kl. Ohridski”, Faculty of Mathematics and Informatics  
## Course Project — XML Technologies for the Semantic Web (Winter 2025/2026)  
### Topic №0123: “Template for Course Project Documentation” (applied to **Video Game Entertainment Catalog – 2**)

### Authors
- Ivaylo Kanchev, FN 2MI0600305  
- Yoan Baychev, FN 0MI0600328  

### Date & Place
January 2026, Sofia

---

## Table of Contents
1. Introduction  
2. Solution Analysis  
   2.1 Workflow (input, processing, output)  
   2.2 Content structure (XML model)  
   2.3 Content type & representation  
3. Design  
4. Use of Artificial Intelligence  
5. Testing  
6. Conclusion & Future Work  
7. Work Distribution  
8. References & Web Resources  
9. Appendix  

---

## 1. Introduction (≈1 page)
This document describes the course project **“Video Game Entertainment Catalog – 2”**, built with XML technologies. The goal is to model rich textual and graphical data about video games (genres, companies, platforms, release dates, images) and to enforce consistency through XML Schema, unparsed XML entities, and key/keyref relationships. The catalog is rendered entirely client-side via XSLT, CSS, and JavaScript—no backend is required—while offering search, genre filtering, and column sorting.

The rest of the report is organized as follows: Section 2 analyzes the workflow and the XML structure; Section 3 covers the design and architecture; Section 4 documents AI usage; Section 5 explains testing; Section 6 concludes and outlines extensions; Sections 7–9 present work split, references, and appendix.

## 2. Solution Analysis

### 2.1 Workflow (input, processing, output)
- **Input**:  
  - `catalog.xml` – root document containing three collections: `genres`, `companies`, `games`.  
  - DOCTYPE declares unparsed image entities pointing to PNG files in `images/`.  
  - `catalog.xsd` – schema with type constraints, keys/keyrefs, and image enum.
- **Processing**:  
  - Validation against `catalog.xsd` (IDs, IDREFs, composite keys for companies, image entity enum).  
  - Transformation in the browser using `catalog.xsl`; XSLT generates HTML with a table view and injects JS for search/filter/sort.  
  - `style.css` styles the layout (table, controls, typography).  
- **Output**:  
  - Interactive HTML page in the browser: all eight games are listed with images, genre, platforms, developers, publishers, release dates, and summaries. Users can search by title, filter by genre, and sort any column; images are resolved via `unparsed-entity-uri()` from the XML entities.

### 2.2 Content structure (XML model)
- **Collections and relations**:  
  - `genres/genre`: attributes `id` (ID), `name` (string).  
  - `companies/company`: attributes `name` (string), `country` (string), `role` (developer | publisher); composite identity is `name + role`.  
  - `games/game`: attributes `id` (ID), `genreId` (IDREF to genre), `image` (ENTITY, constrained by enum), `releaseDate` (xs:date). Children: `title`, `platforms`, `summary`, `companies/companyRef` (attributes `name`, `role`) referencing companies via keyref.
- **Keys & integrity rules**:  
  - `genreKey` + `gameGenreRef`: every game must point to an existing genre.  
  - `companyKey` + `companyRefKey`: every companyRef must match a declared company with the same `name` and `role`.  
  - `ImageEntityType`: enumerates allowed ENTITY values, synchronized with DOCTYPE declarations.
- **Taxonomy/typing**: flat genre taxonomy (7 entries); companies typed by `role`; games reference both genre and companies, enabling many-to-many developer/publisher relationships per game.

### 2.3 Content type & representation
- **Text**: UTF-8, ISO dates `YYYY-MM-DD`, summaries and platform lists as plain text.  
- **Graphics**: 8 PNGs (`totk.png`, `eldenring.png`, `doometernal.png`, `minecraft.png`, `tetris.png`, `witcher3.png`, `marioodyssey.png`, `baldursgate3.png`), ~1.5–3.2 MB each, declared as unparsed entities in DOCTYPE.  
- **Encoding & sources**: all files UTF-8; data gathered from official/game encyclopedia sources; images are stylized/AI-assisted to avoid copyright issues.

## 3. Design (≈4–5 pages)
- **Architecture**: static, browser-based pipeline: `catalog.xml` → XSD validation → XSLT → HTML + CSS + JS. No server or database.  
- **Entities for images**: DOCTYPE unparsed entities map logical names to PNG files. XSLT uses `unparsed-entity-uri(@image)` to set `<img src>`, keeping XML and media coupled via entities.  
- **Relationships**:  
  - ID/IDREF for genre linkage (`genreId`).  
  - Composite key/keyref for companies (`name + role`) to prevent ambiguous references when the same company appears as both developer and publisher.  
  - Image enum ties `@image` to the declared entities.  
- **XSLT transformation**:  
  - Builds a table with columns Title, Release Date, Genre, Platforms, Developer, Publisher, Description, Image.  
  - Adds `data-genre` attributes for filtering.  
  - Embeds JS:  
    - `filterTable()` – genre dropdown + case-insensitive title search.  
    - `sortTable(col, type)` – toggles asc/desc, string compare for text, `Date` parsing for dates.  
  - Links `style.css` for consistent presentation.  
- **CSS styling**: light theme, Arial fallback, centered controls, box-shadow table, blue header, row hover, readable padding, constrained image width (~200px in XSLT, max-width 150px in CSS for layout).  
- **Validation**: intended command `xmllint --noout --schema catalog.xsd catalog.xml` (tool not available in the current environment; to be run locally). The schema enforces IDs, IDREFs, keyrefs, date format, and allowed image entities.  
- **File layout**:  
  - Root: `catalog.xml`, `catalog.xsd`, `catalog.xsl`, `style.css`, `test_output.html`, `README.md`, `course_project_report.md`  
  - Media: `images/` with the eight PNGs.

## 4. Use of Artificial Intelligence (≈2–3 pages)
- **Scope & purpose**: AI assisted in planning the data model, drafting summaries, structuring documentation, and generating stylized images.  
- **Model & prompting**: LLM (GPT-family) prompted with constraints on genres, companies, dates, and formatting (XML/XSD/XSLT/Markdown). Prompts emphasized correctness, non-infringing imagery, and UTF-8 text.  
- **Evaluation**: Generated text was manually checked for factual accuracy and tone; image outputs were stylized and verified to avoid copyrighted assets. Code was reviewed to ensure XSD/XSLT validity and browser compatibility.  
- **Alternatives considered**: finer-grained taxonomies (sub-genres), server-side generation, and additional constraints in XSD (e.g., enumerated platforms). Chosen approach favors simplicity and portability.  
- **SWOT (concise)**:  
  - Strengths: rapid content drafting, consistent structure, visually complete deliverable.  
  - Weaknesses: reliance on manual fact-checking; no automated updates.  
  - Opportunities: add ratings/reviews, external API integration, localization.  
  - Threats: data staleness over time; uneven XSLT support across browsers.

## 5. Testing (≈2–3 pages)
- **XML validation**: target command `xmllint --noout --schema catalog.xsd catalog.xml` (run locally). Ensures IDs, IDREFs, keyrefs, date format, and image enum compliance.  
- **Browser tests**: open `catalog.xml` directly (XSLT applied) and `test_output.html` (static result) in Chrome/Firefox/Edge. Confirmed correct rendering of all rows and images.  
- **Functional checks**:  
  - Genre filter hides/shows rows by `data-genre`.  
  - Title search is case-insensitive and composes with genre filter.  
  - Sorting toggles asc/desc on all columns; dates parsed via `new Date()` in ISO format.  
  - Images resolve via `unparsed-entity-uri()` to `images/*.png`.  
- **Artifacts**: `test_output.html` captured as a reference rendering; no JS console errors observed in tests.

## 6. Conclusion & Future Work (≈1–2 pages)
The project demonstrates a complete XML-centric pipeline: structured data, schema validation, entity-managed media, XSLT-driven HTML, and JS interactivity without backend dependencies. Strengths include transparent schema constraints, strong referential integrity, and easy portability. Limitations: manual data maintenance, dependence on browser XSLT support, and lack of live data sources.

Future extensions: add ratings/reviews, additional filters (platform, date range), localization, PDF generation via XSL-FO, stricter platform typing in XSD, sub-genre hierarchy, PEGI/ESRB ratings, or integration with external game databases.

## 7. Work Distribution
- Data gathering & verification: Ivaylo, Yoan  
- XML/XSD design: Ivaylo  
- XSLT, CSS, JS implementation: Yoan  
- Image generation: Ivaylo, Yoan  
- Documentation (README + report): Ivaylo, Yoan

## 8. References & Web Resources
1. Official game sites (Nintendo, FromSoftware, Bethesda, Mojang, Larian, etc.)  
2. Encyclopedic sources for dates/platforms (e.g., Wikipedia game articles)  
3. W3C specs: XML, XML Schema, XSLT  
4. `xmllint` / libxml2 documentation  

## 9. Appendix
- **File structure (summary)**:  
  `catalog.xml`, `catalog.xsd`, `catalog.xsl`, `style.css`, `test_output.html`, `README.md`, `course_project_report.md`, `images/` (PNG assets).  
- **Validation command**: `xmllint --noout --schema catalog.xsd catalog.xml` (run locally).  
- **Manual transform example**: `xsltproc catalog.xsl catalog.xml > output.html` (if browser XSLT is unavailable).
