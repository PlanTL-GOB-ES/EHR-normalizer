#!/usr/bin/perl
#
# Usage: 
# 
#   convertPDF.pl [options] 
#
#

=head1 NAME

convertPDF - An script to convert PDF files into HTML, TXT of XML files.

=head1 SYNOPSIS

 convertPDF.pl [options] 

  Help Options:
   --input format      Input format: PDF, HTML or TXT.
   --output format     Output format: HTML, TXT or XML.
   --sim number        Similarity threshold for header detection.
   --defheader string  Default header if first line is not a header.
   --headers           Use format information to identify possible headers.
   --useformat         Use format information to identify other characteristics.
   --help              Show this scripts help information.
   --manual            Read this scripts manual.

=cut

=head1 OPTIONS

=over 8

=item B<--help>
Show the brief help information.

=item B<--manual>
Read the manual, with examples.

=back

=cut


=head1 EXAMPLES

  The following are examples of this script:

   $ convertPDF.pl --input TXT
   $ convertPDF.pl --input HTML --output TXT --sim 0.78
   $ convertPDF.pl --input PDF --output XML (does this by default)
   $ convertPDF.pl --useformat
   $ convertPDF.pl --headers --useformat
   $ convertPDF.pl --dir /home/user/my-root-dir/

  Note: Place all PDF files inside a "PDF/" directory of your root
 directory.

=cut


=head1 DESCRIPTION

  This script converts PDF files to HTML, TXT or XML. It  uses PDFMiner
 to process PDF files and convert them into HTML files with exact layout,
 and then it can convert these HTML files into TXT or XML. 

  Additionally, the script can detect headers from clinical records and 
 restore lines that has been truncated by a previous PDF conversion.

=cut


=head1 AUTHOR

 Aitor-Gonzalez-Agirre
 --
 aitor.gonzalezagirre@gmail.com

=cut


use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;

#  Command line variables
my $INPUT_FORMAT = "PDF";
my $OUTPUT_FORMAT = "XML";
my $ROOT_DIR = "../documents";
my $SIM_THRESHOLD = 0.75;
my $DEFAULT_HEADER = "DEFAULT_HEADER";
my $DEBUG = 0;

# Use format information to identify posisible headers and privacy information.
my $DETECT_HEADERS = 0;
my $USE_FORMAT = 0;

# Parse command line arguments.
parseCommandLineArguments();

## Process files
chdir("scripts/") or die "Cannot change directory: $!\n";

my $args = "";
if ($DETECT_HEADERS) { $args = $args ." --headers"; }
if ($USE_FORMAT) { $args = $args ." --useformat"; }

if ($INPUT_FORMAT eq "PDF") {
    if ($OUTPUT_FORMAT eq "TXT") {
	print "\nConverting PDF files into HTML....\n\n";
        system ("./pdf-to-html.pl --dir $ROOT_DIR");
	print "\nConverting HTML files into TXT....\n\n";
        system ("./html-to-txt.pl --dir $ROOT_DIR $args");
    }
    elsif ($OUTPUT_FORMAT eq "XML") {
	print "\nConverting PDF files into HTML....\n\n";
        system ("./pdf-to-html.pl --dir $ROOT_DIR");
	print "\nConverting HTML files into TXT....\n\n";
	
        system ("./html-to-txt.pl --dir $ROOT_DIR $args");
	print "\nConverting TXT files into XML....\n\n";
        system ("./txt-to-xml.pl --dir $ROOT_DIR --sim $SIM_THRESHOLD --defheader $DEFAULT_HEADER");
    }
    else {
        system ("Output format $OUTPUT_FORMAT is not supported!");
    }
}
elsif ($INPUT_FORMAT eq "HTML") {
    if ($OUTPUT_FORMAT eq "TXT") {
	print "\nConverting HTML files into TXT....\n\n";
        system ("./html-to-txt.pl --dir $ROOT_DIR $args");
    }
    elsif ($OUTPUT_FORMAT eq "XML") {
	print "\nConverting HTML files into TXT....\n\n";
        system ("./html-to-txt.pl --dir $ROOT_DIR $args");
	print "\nConverting TXT files into XML....\n\n";
        system ("./txt-to-xml.pl --dir $ROOT_DIR --sim $SIM_THRESHOLD --defheader $DEFAULT_HEADER");
    }
    else {
        die "Output format $OUTPUT_FORMAT is not supported!\n";
    }	
}
elsif ($INPUT_FORMAT eq "TXT") {
    if ($OUTPUT_FORMAT eq "XML") {
	print "\nConverting TXT files into XML....\n\n";
        system ("./txt-to-xml.pl --dir $ROOT_DIR --sim $SIM_THRESHOLD --defheader $DEFAULT_HEADER");
    }
    else {
        die "Output format $OUTPUT_FORMAT is not supported!\n";
    }
}
else {
    die "Input format $INPUT_FORMAT is not supported!\n";
}


=head2 parseCommandLineArguments

  Parse the arguments specified upon the command line.

=cut

sub parseCommandLineArguments
{
    my $HELP    = 0;   # Show help overview.
    my $MANUAL    = 0;   # Show manual

    #  Parse options.
    #
    GetOptions(
           "input=s",      \$INPUT_FORMAT,
           "output=s",      \$OUTPUT_FORMAT,
           "dir=s",        \$ROOT_DIR,
           "sim=f",        \$SIM_THRESHOLD,
           "defheader=s",  \$DEFAULT_HEADER,
           "headers",      \$DETECT_HEADERS,
           "useformat",    \$USE_FORMAT,
           "debug",        \$DEBUG,
           "help",         \$HELP,
           "manual",       \$MANUAL,
          );
    
    pod2usage(1) if $HELP;
    pod2usage(-verbose => 2 ) if $MANUAL;

    pod2usage if $#ARGV >0 ;

}
