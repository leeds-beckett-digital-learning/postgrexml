<?xml version="1.0" encoding="UTF-8"?>

<!--
    Document   : xmltosql.xsl
    Created on : 26 October 2025, 19:01
    Author     : jon
    Description:
        This takes an XML model file and transforms it to a PostreSQL compatible SQL query
        that, when executed will output an XML representation of the requested data based
        on the model.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pgxml="http://leedsbeckett.ac.uk/postgrexml" version="1.0">
  <xsl:output method="text" indent="no"/>

  <xsl:variable name="nl">
    <xsl:text>&#x0a;</xsl:text>
  </xsl:variable>

  <xsl:variable name="apos">
    <xsl:text>&apos;</xsl:text>
  </xsl:variable>

  <xsl:template match="*">
    <xsl:choose>
      <xsl:when test="count(ancestor::*) = 0">
        <xsl:value-of select="concat( 'SELECT', $nl )"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>,</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="." mode="element"/>
  </xsl:template>

  <xsl:template match="*[count( @pgxml:from | @pgxml:where ) = 2]">

    <xsl:if test="count(ancestor::*) != 0">
      <xsl:text>,</xsl:text>
    </xsl:if>
    
    <xsl:value-of select="concat( '(', $nl, 'SELECT xmlagg( xmlconcat(',  $nl )"/>
      <xsl:variable name="precedingnode" select="(./preceding-sibling::* | ./preceding-sibling::text())[1]" />
      <xsl:variable name="pretext" select="string( $precedingnode )"/>
    
      <xsl:if test="name($precedingnode) = '' and count($precedingnode) = 1">
        <xsl:call-template name="string-literal">
          <xsl:with-param name="text" select="$pretext" />
        </xsl:call-template>
        <xsl:value-of select="', '"/>
      </xsl:if>

      <xsl:apply-templates select="." mode="element"/>

    <xsl:value-of select="concat( '))', $nl, 'FROM ', @pgxml:from, ' WHERE ', @pgxml:where, $nl, ')', $nl )"/>    
  </xsl:template>

  <xsl:template match="*" mode="pretext">
  </xsl:template>

  <xsl:template match="*" mode="element">
    <xsl:value-of select="concat( 'xmlelement( name ', name(.), $nl )"/>
    <xsl:apply-templates select="." mode="attributes"/>
    <xsl:apply-templates select="*|text()" mode=""/>
    <xsl:value-of select="concat( ' )', $nl )"/>
  </xsl:template>
  
  <xsl:template match="*" mode="attributes">
    <xsl:if test="count(@*[namespace-uri()='']) != 0">
      <xsl:value-of select="', xmlattributes( '"/>
      <xsl:for-each select="@*[namespace-uri()='']">
        <xsl:if test="position() != 1">,</xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <xsl:value-of select="concat( ' )', $nl )"/> 
    </xsl:if>    
  </xsl:template>

  <xsl:template match="pgxml:field[ count(@pgxml:expression) = 1 ]">
    <xsl:value-of select="', '"/>
    <xsl:value-of select="@pgxml:expression"/>
  </xsl:template>

  <xsl:template match="@*">
    <xsl:choose>
      <xsl:when test="starts-with(.,'sql;')">
        <xsl:value-of select="concat( substring(.,5) , ' AS ', name() )"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat( $apos, ., $apos, ' AS ', name() )"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:variable name="followingnode" select="(./following-sibling::* | ./following-sibling::text())[1]" />
    <!-- Output the text if the following sibling is not an element or -->
    <!-- is a non-repeating element.                                   -->
    <xsl:if test="name($followingnode) = '' or $followingnode[count( @pgxml:from | @pgxml:where ) != 2]">
      <xsl:value-of select="', '"/>
      <xsl:call-template name="string-literal">
        <xsl:with-param name="text" select="string(.)" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="string-literal">
    <xsl:param name="text" />
    <xsl:value-of select="concat( 'E', $apos )"/>
    <xsl:call-template name="string-replace-all">
      <xsl:with-param name="text" select="$text" />
      <xsl:with-param name="replace" select="'&#x0a;'" />
      <xsl:with-param name="by" select="'\n'" />
    </xsl:call-template>

    <xsl:value-of select="concat( $apos, $nl )"/>
  </xsl:template>

  <xsl:template name="string-replace-all">
    <xsl:param name="text" />
    <xsl:param name="replace" />
    <xsl:param name="by" />
    <xsl:choose>
      <xsl:when test="$text = '' or $replace = ''or not($replace)" >
        <!-- Prevent this routine from hanging -->
        <xsl:value-of select="$text" />
      </xsl:when>
      <xsl:when test="contains($text, $replace)">
        <xsl:value-of select="substring-before($text,$replace)" />
        <xsl:value-of select="$by" />
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="substring-after($text,$replace)" />
          <xsl:with-param name="replace" select="$replace" />
          <xsl:with-param name="by" select="$by" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
