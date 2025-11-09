<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" encoding="UTF-8" indent="yes"/>

    <xsl:param name="sortBy" select="'title'"/>

    <xsl:key name="genreById" match="genre" use="@id"/>
    <xsl:key name="companyById" match="company" use="@id"/>
    <xsl:key name="platformById" match="platform" use="@id"/>

    <xsl:template match="/">
        <table class="game-table">
            <thead>
                <tr>
                    <th>Изображение</th>
                    <th>Име</th>
                    <th>Жанр</th>
                    <th>Компания</th>
                    <th>Платформи</th>
                    <th>Година</th>
                    <th>Възраст</th>
                    <th>Мултиплейър</th>
                    <th>Цена</th>
                    <th>Описание</th>
                </tr>
            </thead>
            <tbody>
                <xsl:choose>
                    <xsl:when test="$sortBy = 'genre'">
                        <xsl:for-each select="videogameCatalog/games/game">
                            <xsl:sort select="key('genreById', genreId)" data-type="text"/>
                            <xsl:call-template name="game-row"/>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="$sortBy = 'year'">
                        <xsl:for-each select="videogameCatalog/games/game">
                            <xsl:sort select="releaseYear" data-type="number"/>
                            <xsl:call-template name="game-row"/>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="videogameCatalog/games/game">
                            <xsl:sort select="title" data-type="text"/>
                            <xsl:call-template name="game-row"/>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </tbody>
        </table>
    </xsl:template>

    <xsl:template name="game-row">
        <tr>
            <td>
                <img class="cover">
                    <xsl:attribute name="src">
                        <xsl:value-of select="image"/>
                    </xsl:attribute>
                    <xsl:attribute name="alt">
                        <xsl:value-of select="title"/>
                    </xsl:attribute>
                </img>
            </td>
            <td><xsl:value-of select="title"/></td>
            <td><xsl:value-of select="key('genreById', genreId)"/></td>
            <td><xsl:value-of select="key('companyById', companyId)/name"/></td>
            <td>
                <xsl:for-each select="platformId">
                    <xsl:value-of select="key('platformById', .)"/>
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </td>
            <td><xsl:value-of select="releaseYear"/></td>
            <td><xsl:value-of select="ageRating"/></td>
            <td>
                <xsl:choose>
                    <xsl:when test="multiplayer = 'true'">Да</xsl:when>
                    <xsl:otherwise>Не</xsl:otherwise>
                </xsl:choose>
            </td>
            <td>
                <xsl:value-of select="format-number(price, '0.00')"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="price/@currency"/>
            </td>
            <td><xsl:value-of select="description"/></td>
        </tr>
    </xsl:template>

</xsl:stylesheet>

