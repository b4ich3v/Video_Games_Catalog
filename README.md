# Course Project: Video Game Entertainment Catalog – 2 (Topic 39)

**Students:** Ivaylo Kanchev (`2MI0600305`), Yoan Baychev (`0MI0600328`)  
**Date:** 25 November 2025

## 1. Introduction

This document describes the development of a course project in XML technologies.  
The assignment is to **create a video game entertainment catalog**, where the
content is structured in an XML document validated through an XML Schema.
The catalog presents textual and graphical information about the games, with
images linked through unparsed XML entities. The data is visualized in a web
browser using CSS and XSLT, enhanced with JavaScript features for filtering and
sorting.

For the base implementation, we were required to describe **7–8 games**
from different genres, specifying developers, publishers, platforms, and release
dates. Additionally, the project expands the requirements by implementing an
interactive catalog that supports search by title and filtering by genre.

## 2. Task Analysis

### 2.1 Selection of Games and Sources

We selected eight popular video games spanning different years, genres, and
platforms. Information was collected from official websites and reputable
encyclopedias to gather accurate details about developers, publishers, release
dates, and platforms.

### 2.2 Relationships and Constraints

The catalog defines relationships between genres, companies, and games using
composite keys and references. Each game belongs to a genre, and companies
(developers/publishers) are referenced through a two-attribute key system.
Images are connected via unparsed XML entities, resolved with
`unparsed-entity-uri()` in XSLT.

### 2.3 Enhancements for Higher Grade

To meet the requirements for a higher grade, we implemented:

- **Search functionality** – dynamic filtering by title  
- **Genre filter** – dropdown selector  
- **Column sorting** – JavaScript sorting for all fields  

These features turn the catalog into an interactive web application.

## 3. Design and Implementation

### 3.1 XML Structure

The XML document contains three major collections:

- `genres` – list of game genres  
- `companies` – developers and publishers  
- `games` – game entries with references to genres and companies  

### 3.2 XML Schema (XSD)

The XSD defines all element structures and constraints. A custom type
`ImageEntityType` ensures that images refer only to declared entities.
Composite company identity is validated via a key-keyref pair.

### 3.3 XSLT and JavaScript

The XSLT stylesheet transforms XML into HTML, displays all games in a table, and
injects images using unparsed-entity references. JavaScript implements sorting
and filtering, while CSS provides styling and layout.

### 3.4 File Structure

```
xml_video_game_catalog/
├── catalog.xml
├── catalog.xsd
├── catalog.xsl
├── style.css
├── images/
│   ├── totk.png
│   ├── eldenring.png
│   ├── doometernal.png
│   ├── minecraft.png
│   ├── tetris.png
│   ├── witcher3.png
│   ├── marioodyssey.png
│   └── baldursgate3.png
└── README.md
```

### 3.5 Validation and Testing

Validation was performed with:

```
xmllint --noout --schema catalog.xsd catalog.xml
```

Testing in a browser confirmed that XSLT is applied correctly and all interactive
features work smoothly.

## 4. Use of Generative AI

AI tools were used for:

- Project planning and structural design  
- Assistance with descriptions, formatting, and explanations  
- Generating stylized game images without violating copyright  
- Markdown formatting and documentation layout  

## 5. Conclusion

The resulting catalog meets all assignment requirements:  
structured data, XSD validation, key/keyref relationships, unparsed entities for
images, and an interactive browser view via XSLT, CSS, and JavaScript. Future
extensions could include adding ratings, reviews, or external APIs.

## 6. Work Distribution

| Task | Ivaylo Kanchev | Yoan Baychev |
|------|----------------|--------------|
| Gathering and verifying game information | X | X |
| Designing XML/XSD structure | X |  |
| XSLT, CSS, JS implementation |  | X |
| Image generation | X | X |
| Report preparation | X | X |
