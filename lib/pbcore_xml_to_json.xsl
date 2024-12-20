<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="text" encoding="utf-8" />

	<xsl:template match="/node()">
		<xsl:text>{</xsl:text>
		<xsl:apply-templates select="." mode="detect" />
		<xsl:text>}</xsl:text>
	</xsl:template>

	<xsl:template name="escape-characters">
		<xsl:param name="text" />
		<!-- Replace backslashes -->
		<xsl:variable name="escapedBackslashes">
			<xsl:call-template name="replace">
				<xsl:with-param name="text" select="$text" />
				<xsl:with-param name="search" select="'\'" />
				<xsl:with-param name="replace" select="'\\'" />
			</xsl:call-template>
		</xsl:variable>
		<!-- Replace quotes -->
		<xsl:variable name="escapedQuotes">
			<xsl:call-template name="replace">
				<xsl:with-param name="text" select="$escapedBackslashes" />
				<xsl:with-param name="search" select="'&quot;'" />
				<xsl:with-param name="replace" select="'\&quot;'" />
			</xsl:call-template>
		</xsl:variable>
		<!-- Replace newline characters -->
		<xsl:variable name="escapedNewlines">
			<xsl:call-template name="replace">
				<xsl:with-param name="text" select="$escapedQuotes" />
				<xsl:with-param name="search" select="'&#xA;'" />
				<xsl:with-param name="replace" select="'\n'" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="$escapedNewlines" />
	</xsl:template>

	<!-- Utility template to perform string replacement -->
	<xsl:template name="replace">
		<xsl:param name="text" />
		<xsl:param name="search" />
		<xsl:param name="replace" />
		<xsl:choose>
			<xsl:when test="contains($text, $search)">
				<xsl:value-of select="substring-before($text, $search)" />
				<xsl:value-of select="$replace" />
				<xsl:call-template name="replace">
					<xsl:with-param name="text" select="substring-after($text, $search)" />
					<xsl:with-param name="search" select="$search" />
					<xsl:with-param name="replace" select="$replace" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Detect the type of node and apply the appropriate template -->
	<xsl:template match="*" mode="detect">
		<xsl:choose>
			<xsl:when
				test="name(preceding-sibling::*[1]) = name(current()) and name(following-sibling::*[1]) != name(current())">
				<xsl:apply-templates select="." mode="obj-content" />
				<xsl:text>]</xsl:text>
				<xsl:if test="count(following-sibling::*[name() != name(current())]) &gt; 0">, </xsl:if>
			</xsl:when>
			<xsl:when test="name(preceding-sibling::*[1]) = name(current())">
				<xsl:apply-templates select="." mode="obj-content" />
				<xsl:if test="name(following-sibling::*) = name(current())">, </xsl:if>
			</xsl:when>
			<xsl:when test="following-sibling::*[1][name() = name(current())]">
				<xsl:text>"</xsl:text>
				<xsl:value-of select="name()" />
				<xsl:text>" : [</xsl:text>
				<xsl:apply-templates select="." mode="obj-content" />
				<xsl:text>, </xsl:text>
			</xsl:when>
			<xsl:when test="count(./child::*) > 0 or count(@*) > 0">
				<xsl:text>"</xsl:text><xsl:value-of select="name()" />" : <xsl:apply-templates select="."
					mode="obj-content" />
				<xsl:if test="count(following-sibling::*) &gt; 0">, </xsl:if>
			</xsl:when>
			<xsl:when test="count(./child::*) = 0">
				<xsl:text>"</xsl:text>
				<xsl:value-of select="name()" />
				<xsl:text>" : "</xsl:text>
				<xsl:call-template name="escape-characters">
					<xsl:with-param name="text" select="." />
				</xsl:call-template>
				<xsl:text>"</xsl:text>
				<xsl:if test="count(following-sibling::*) &gt; 0">, </xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<!-- Output the content of the node -->
	<xsl:template match="*" mode="obj-content">
		<xsl:text>{</xsl:text>
		<xsl:apply-templates select="@*" mode="attr" />
		<xsl:if test="count(@*) &gt; 0 and (count(child::*) &gt; 0 or text())">, </xsl:if>
		<xsl:apply-templates select="./*" mode="detect" />
		<xsl:if test="count(child::*) = 0 and text() and not(@*)">
			<xsl:text>"</xsl:text><xsl:value-of select="name()" />" : "<xsl:value-of
				select="normalize-space(text())" /><xsl:text>"</xsl:text>
		</xsl:if>
		<xsl:if test="count(child::*) = 0 and text() and @*">
			<xsl:text>"text" : "</xsl:text>
			<xsl:call-template name="escape-characters">
				<xsl:with-param name="text" select="normalize-space(.)" />
			</xsl:call-template>
			<xsl:text>"</xsl:text>
		</xsl:if>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() &lt; last()">, </xsl:if>
	</xsl:template>

	<!-- Output the attributes of the node -->
	<xsl:template match="@*" mode="attr">
		<xsl:text>"</xsl:text><xsl:value-of select="name()" />" : "<xsl:value-of select="." /><xsl:text>"</xsl:text>
		<xsl:if
			test="position() &lt; last()">,</xsl:if>
	</xsl:template>

	<!-- Remove line breaks from text nodes -->
	<xsl:template match="node/@TEXT | text()" name="removeBreaks">
		<xsl:param name="pText" select="normalize-space(.)" />
		<xsl:choose>
			<xsl:when test="not(contains($pText, ' &#xA;'))">
				<xsl:copy-of select="$pText" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat(substring-before($pText, ' &#xD;&#xA;'), ' ')" />
				<xsl:call-template name="removeBreaks">
					<xsl:with-param name="pText" select="substring-after($pText, '
	&#xD;&#xA;')" />
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>