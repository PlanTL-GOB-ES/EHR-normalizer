#!/usr/bin/perl
#
# Usage: 
# 
#   pdf-to-html.pl [options] 
#
#

=head1 NAME

pdf-to-html - An script to convert PDF files into HTML files.

=head1 SYNOPSIS

 pdf-to-html.pl [options] 

  Help Options:
   --dir directory     Use another root directory.
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

   $ pdf-to-html.pl
   $ pdf-to-html.pl --dir /home/user/my-root-dir/

  Note: Place all PDF files inside a "PDF/" directory of your root
 directory.

=cut


=head1 DESCRIPTION

  This script uses PDFMiner to process PDF files and convert them
 into HTML files with exact layout.

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

# Default directory
my $ROOT_DIR = "../documents";

# Parse command line arguments.
parseCommandLineArguments();

## Process PDF files
processPdf ("$ROOT_DIR/PDF");



################################
######### SUB-ROUTINES #########
################################


# Accepts one argument: the full path to a custom directory.
# Returns: nothing.
sub processPdf {
    my $path = shift;

    # Open the directory.
    opendir (DIR, $path) or die "Unable to open $path: $! (Please place your files in $path directory)";

    # Read in the files.
    # Skip '.' and '..' files,
    my @files = grep { !/^\.{1,2}$/ } readdir (DIR);

    # Close the directory.
    closedir (DIR);

    # Concatenate 'filename' with full path using map()
    @files = map { $path . '/' . $_ } @files;

    # Create target directory if it does not exist
    (my $target_path = $path) =~ s/PDF/HTML/g;
    mkdir $target_path unless -d $target_path;

    # Start processing files
    print "Processing \'$path\/\'...\n";

    foreach my $source (sort @files) {

	($target_path = $source) =~ s/PDF/HTML/g;

        # If the file is a directory
        if (-d $source) {
            # Here where we recurse if we found a sub-directory
            # Create target sub-directory if it does not exist
            mkdir $target_path unless -d $target_path;

	    # Process files
            processPdf ($source);
	
        # If it is a file, process it
        } else { 
            # We call PDFMiner to process the file
	    system("pdf2txt.py -t html -Y exact $source  >  $target_path.html");
        }
	
    }    
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
           "dir=s",  \$ROOT_DIR,
           "help",   \$HELP,
           "manual", \$MANUAL,
          );
    
    pod2usage(1) if $HELP;
    pod2usage(-verbose => 2 ) if $MANUAL;

    pod2usage if $#ARGV >0 ;

}
