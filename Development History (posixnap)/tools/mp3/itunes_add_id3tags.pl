#!/usr/bin/perl

# see http://use.perl.org/~ziggy/journal/9780
 
use strict;
use warnings;
 
use MP3::Info;
 
my @id3_fields = qw(Location Name Artist Album Year Comment Genre);
push(@id3_fields, "Track Number");
 
use_winamp_genres();
 
sub read_metadata {
	my $filename = shift;
	use XML::LibXSLT;
	use XML::LibXML;
	 
	$/ = undef;
	 
	my $parser = XML::LibXML->new();
	my $xslt = XML::LibXSLT->new();
	 
	my $source = $parser->parse_file($filename);
	my $style_doc = $parser->parse_string(<DATA>);
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	 
	my $results = $stylesheet->transform($source);
	 
	return $stylesheet->output_string($results);
}
 
## Update ID3 tags
 
print STDERR "Processing 'iTunes Music Library.xml'...";
my $metadata = read_metadata("$ENV{HOME}/Music/iTunes/iTunes Music Library.xml");
print STDERR "done\n";
 
my @blocks = split("\n\n", $metadata);
 
foreach my $block (@blocks) {
    my (%info) = map {m/^(\w+): (.*)$/} split("\n", $block);
 
    $info{Location} =~ s{^file://localhost}{};
    $info{Location} =~ s{%20}{ }g;
 
    print STDERR "$info{Artist}: $info{Album}, $info{Name}\n";
 
    $info{Genre} = 'Dance' if $info{Genre} eq "Electronica/Dance";
    $info{Genre} = 'Other' if $info{Genre} eq "World";
    $info{Genre} = 'Alternative' if $info{Genre} eq "Alternative & Punk";
 
    set_mp3tag(@info{@id3_fields});
}
 
__DATA__
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
version="1.0">
 
<xsl:outp ut method="text"/>
 
<xsl:template match="text()"/>
 
<xsl:template match="plist/dict/dict[preceding-sibling::key[text() = 'Tracks']]">
 <xsl:apply-templates select="dict" mode="display"/>
</xsl:template>
 
<xsl:template match="dict" mode="display">
 <xsl:apply-templates select="key[. = 'Location']" mode="display"/>
 <xsl:apply-templates select="key[. = 'Name']" mode="display"/>
 <xsl:apply-templates select="key[. = 'Artist']" mode="display"/>
 <xsl:apply-templates select="key[. = 'Album']" mode="display"/>
 <xsl:apply-templates select="key[. = 'Year']" mode="display"/>
 <xsl:apply-templates select="key[. = 'Genre']" mode="display"/>
 <xsl:apply-templates select="key[. = 'Track Number']" mode="display"/>
 <xsl:text>&#xa;</xsl:text>
</xsl:template>
 
<xsl:templa te match="key" mode="display">
 <xsl:value-of select="concat(text(), ': ', following-sibling::*/text(), '&#xa;')"/>
</xsl:template>
 
</xsl:stylesheet> 
