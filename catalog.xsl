<?xml version="1.0" encoding="UTF-8"?>
<!--
  XSLT стилов лист, който преобразува catalog.xml в интерактивен HTML документ.
  Съдържа генериране на таблица на игрите, позволяваща сортиране и филтриране
  на данните чрез JavaScript.  Изображенията се извличат чрез функциите
  unparsed-entity-uri() и се поставят като src атрибути на <img> елементи.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="UTF-8" doctype-system="about:legacy-compat"/>

  <!-- Глобален параметър за сортиране на таблицата може да бъде подаден, ако е необходимо. -->

  <!-- Основен шаблон за корена -->
  <xsl:template match="/catalog">
    <html lang="bg">
      <head>
        <meta charset="UTF-8"/>
        <title>Каталог на видеоигрите</title>
        <link rel="stylesheet" type="text/css" href="style.css"/>
      </head>
      <body>
        <h1>Каталог на видеоигрите</h1>
        <!-- Филтър по жанр -->
        <div class="controls">
          <label for="genreFilter">Филтрирай по жанр:</label>
          <select id="genreFilter" onchange="filterTable()">
            <option value="all">Всички жанрове</option>
            <xsl:for-each select="genres/genre">
              <option value="{@id}"><xsl:value-of select="@name"/></option>
            </xsl:for-each>
          </select>
          <input type="text" id="searchBox" onkeyup="filterTable()" placeholder="Търсене по заглавие…"/>
        </div>

        <table id="gamesTable">
          <thead>
            <tr>
              <th onclick="sortTable(0, 'string')">Заглавие</th>
              <th onclick="sortTable(1, 'date')">Дата на издаване</th>
              <th onclick="sortTable(2, 'string')">Жанр</th>
              <th onclick="sortTable(3, 'string')">Платформи</th>
              <th onclick="sortTable(4, 'string')">Разработчик</th>
              <th onclick="sortTable(5, 'string')">Издател</th>
              <th>Описание</th>
              <th>Снимка</th>
            </tr>
          </thead>
          <tbody>
            <xsl:for-each select="games/game">
              <tr data-genre="{@genreId}">
                <!-- Заглавие -->
                <td class="title"><xsl:value-of select="title"/></td>
                <!-- Дата на издаване -->
                <td class="date"><xsl:value-of select="@releaseDate"/></td>
                <!-- Жанр -->
                <td class="genre">
                  <xsl:variable name="gid" select="@genreId"/>
                  <xsl:value-of select="../../genres/genre[@id=$gid]/@name"/>
                </td>
                <!-- Платформи -->
                <td class="platforms"><xsl:value-of select="platforms"/></td>
                <!-- Разработчик(и) -->
                <td class="developers">
                  <xsl:for-each select="companies/companyRef[@role='developer']">
                    <xsl:if test="position() &gt; 1">, </xsl:if>
                    <xsl:value-of select="@name"/>
                  </xsl:for-each>
                </td>
                <!-- Издател(и) -->
                <td class="publishers">
                  <xsl:for-each select="companies/companyRef[@role='publisher']">
                    <xsl:if test="position() &gt; 1">, </xsl:if>
                    <xsl:value-of select="@name"/>
                  </xsl:for-each>
                </td>
                <!-- Описание -->
                <td class="summary"><xsl:value-of select="summary"/></td>
                <!-- Изображение -->
                <td class="image">
                  <img alt="Изображение" width="200">
                    <xsl:attribute name="src">
                      <xsl:value-of select="unparsed-entity-uri(@image)"/>
                    </xsl:attribute>
                  </img>
                </td>
              </tr>
            </xsl:for-each>
          </tbody>
        </table>

        <!-- JavaScript за сортиране и филтриране -->
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
    if (genreMatch && searchMatch) {
      row.style.display = '';
    } else {
      row.style.display = 'none';
    }
  }
}

var sortState = {};
function sortTable(col, type) {
  var table = document.getElementById('gamesTable');
  var tbody = table.tBodies[0];
  var rows = Array.prototype.slice.call(tbody.rows, 0);
  // Determine the sorting direction
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
  // Append the sorted rows back to the table body
  for (var i = 0; i < rows.length; i++) {
    tbody.appendChild(rows[i]);
  }
}
        ]]></script>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
