<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="UTF-8" doctype-system="about:legacy-compat"/>

  <xsl:template match="/catalog">
    <html lang="en">
      <head>
        <meta charset="UTF-8"/>
        <title>Video Game Catalog</title>
        <link rel="stylesheet" type="text/css" href="style.css"/>
      </head>
      <body>
        <h1>Video Game Catalog</h1>

        <div class="controls">
          <label for="genreFilter">Filter by genre:</label>
          <select id="genreFilter" onchange="filterTable()">
            <option value="all">All genres</option>
            <xsl:for-each select="genres/genre">
              <option value="{@id}">
                <xsl:value-of select="@name"/>
              </option>
            </xsl:for-each>
          </select>

          <input type="text"
                 id="searchBox"
                 onkeyup="filterTable()"
                 placeholder="Search by title"/>

          <button type="button" onclick="sortTable(1, 'date')">
            Sort by release date
          </button>
        </div>

        <table id="gamesTable">
          <thead>
            <tr>
              <th onclick="sortTable(0, 'string')">Title</th>
              <th onclick="sortTable(1, 'date')">Release Date</th>
              <th onclick="sortTable(2, 'string')">Genre</th>
              <th onclick="sortTable(3, 'string')">Platforms</th>
              <th onclick="sortTable(4, 'string')">Developer</th>
              <th onclick="sortTable(5, 'string')">Publisher</th>
              <th>Description</th>
              <th>Image</th>
            </tr>
          </thead>

          <tbody>
            <xsl:for-each select="games/game">
              <tr data-genre="{@genreId}">
                
                <td class="title"><xsl:value-of select="title"/></td>

                <td class="date"><xsl:value-of select="@releaseDate"/></td>

                <td class="genre">
                  <xsl:variable name="gid" select="@genreId"/>
                  <xsl:value-of select="../../genres/genre[@id=$gid]/@name"/>
                </td>

                <td class="platforms">
                  <xsl:value-of select="platforms"/>
                </td>

                <td class="developers">
                  <xsl:for-each select="companies/companyRef[@role='developer']">
                    <xsl:if test="position() &gt; 1">, </xsl:if>
                    <xsl:value-of select="@name"/>
                  </xsl:for-each>
                </td>

                <td class="publishers">
                  <xsl:for-each select="companies/companyRef[@role='publisher']">
                    <xsl:if test="position() &gt; 1">, </xsl:if>
                    <xsl:value-of select="@name"/>
                  </xsl:for-each>
                </td>

                <td class="summary">
                  <xsl:value-of select="summary"/>
                </td>

                <td class="image">
                  <img alt="Image" width="200">
                    <xsl:attribute name="src">
                      <xsl:value-of select="unparsed-entity-uri(@image)"/>
                    </xsl:attribute>
                  </img>
                </td>

              </tr>
            </xsl:for-each>
          </tbody>

        </table>

        <script type="text/javascript"><![CDATA[
function filterTable() {
  var genre = document.getElementById('genreFilter').value;
  var search = document.getElementById('searchBox').value.toLowerCase();
  var table = document.getElementById('gamesTable');
  var rows = table.getElementsByTagName('tbody')[0].getElementsByTagName('tr');

  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    var title = row.getElementsByClassName('title')[0].textContent.toLowerCase();
    var genreMatch = (genre === 'all') || (row.getAttribute('data-genre') === genre);
    var searchMatch = (title.indexOf(search) > -1);

    row.style.display = (genreMatch && searchMatch) ? '' : 'none';
  }
}

var sortState = {};

function sortTable(col, type) {
  var table = document.getElementById('gamesTable');
  var tbody = table.tBodies[0];
  var rows = Array.prototype.slice.call(tbody.rows, 0);

  var dir = sortState[col] === 'asc' ? 'desc' : 'asc';
  sortState[col] = dir;

  rows.sort(function(a, b) {
    var A = a.cells[col].textContent.trim();
    var B = b.cells[col].textContent.trim();

    if (type === 'date') {
      A = new Date(A);
      B = new Date(B);
    } else {
      A = A.toLowerCase();
      B = B.toLowerCase();
    }

    if (A < B) return dir === 'asc' ? -1 : 1;
    if (A > B) return dir === 'asc' ? 1 : -1;
    return 0;
  });

  for (var i = 0; i < rows.length; i++) {
    tbody.appendChild(rows[i]);
  }
}
        ]]></script>

      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
