#!/usr/bin/perl
#
# Usage: 
# 
#   txt-to-xml.pl [options] 
#
#

=head1 NAME

txt-to-xml - An script to convert TXT files into XML files.

=head1 SYNOPSIS

 txt-to-xml.pl [options] 

  Help Options:
   --dir directory     Use another root directory.
   --sim number        Similarity threshold for header detection.
   --defheader string  Default header if first line is not a header.
   --verbose           Print debugging information.
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

   $ txt-to-xml.pl
   $ txt-to-xml.pl --dir /home/user/my-root-dir/

  Note: Place all TXT files inside a "TXT/" directory of your root
 directory.

=cut


=head1 DESCRIPTION

  This script transforms TXT files into TXT files. The script can detect
 headers from clinical records and restore lines that has been truncated
 by a previous PDF conversion.

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
use Encode qw(encode decode);
use String::Similarity;
use Cwd;


#  Command line variables
my $ROOT_DIR = "../documents";
my $SIM_THRESHOLD = 0.75;
my $DEFAULT_HEADER;
my $DEBUG = 0;


# Parse command line arguments.
parseCommandLineArguments();

## Initialize all parameters and load headers
my %max_cols;
my %headers;
my %subheaders;
my $regex;

if ($DEBUG) { 
    open (DEBUG_LINES, ">../debug-lines.txt") or die("Could not open file: debug-lines.txt.");  
    open (DEBUG_HEADERS, ">../debug-heades.txt") or die("Could not open file: debug-heades.txt.");
}

# This script uses UTF-8 encoding
my $enc = 'utf-8'; 

# Initialize parameters
_initialize();

## Process TXT files
processTXT("$ROOT_DIR/TXT");


# Close files
if ($DEBUG) { 
    close(DEBUG_LINES);  
    close(DEBUG_HEADERS);
}


################################
######### SUB-ROUTINES #########
################################

sub _initialize {
    
    ## Load list of known headers and sub-headers
    open (HEADERS, "../data/headers.txt") or die("Could not open file: ../data/headers.txt.");
    while (my $line=<HEADERS>) {
        chomp($line);
   
        (my $section, my $alternative) = split(/\t/, $line);
        $headers{$alternative} = $section;
        $headers{$section} = $section;
    }
    close(HEADERS);

    open (SUBHEADERS, "../data/subheaders.txt") or die("Could not open file: ../data/subheaders.txt.");
    while (my $line=<SUBHEADERS>) {
        chomp($line);
   
        my ($section, $subsection, $alternative) = split(/\t/, $line);
        $subheaders{$section}->{$alternative} = $subsection;
        $subheaders{$section}->{$subsection} = $subsection;	
    }
    close(SUBHEADERS);


    # Load patterns to remove noise from file
    open(NOISEFILE, "<../data/patterns-to-remove.txt"); 
    my @noise_patterns = <NOISEFILE>;
    chomp(@noise_patterns);
    $regex = join( '|', @noise_patterns );
    $regex = qr/(?:$regex)/;
    #print "Using regex of: $regex\n";
    close(NOISEFILE);

}

# Accepts one argument: the full path to a custom directory.
# Returns: nothing.
sub processTXT {
    my $path = shift;

    # Open the directory.
    opendir (DIR, $path) or die "Unable to open $path: $!";

    # Read in the files.
    # Skip '.' and '..' files,
    my @files = grep { !/^\.{1,2}$/ } readdir (DIR);

    # Close the directory.
    closedir (DIR);

    # Concatenate 'filename' with full path using map()
    @files = map { $path . '/' . $_ } @files;

    # Create target directory if it does not exist
    (my $target_path = $path) =~ s/TXT/XML/g;
    mkdir $target_path unless -d $target_path;

    # Start processing files
    print "Processing \'$path\/\'...\n";

    foreach my $source (sort @files) {

	($target_path = $source) =~ s/TXT/XML/g;

        # If the file is a directory
        if (-d $source) {
            # Here where we recurse if we found a sub-directory
            # Create target sub-directory if it does not exist
            mkdir $target_path unless -d $target_path;

	    # Process files
            processTXT ($source);
	
        # If it is a file, process it
        } else { 

            # Process XML file
            printToXML($source,$target_path);
        }
	
    }    
}


sub printToXML {

    my $source = shift;
    my $target_path = shift; #print "$target_path\n"; sleep(10);
	
    # Get document width
    my $file_width = `wc -L < $source`;
            
    # Open files
    open(IN, "$source") or die("Could not open file: $source.");
    open(OUT, ">$target_path.xml") or die("Could not open file: $target_path.xml");
            

    # Split source path 
    $source =~ s/(.+)\/(.+)\/(.+\.txt)//g;
    my $root_dir = $1;
    my $dir = $2;
    my $file = $3;

    ## Print headers to XML
    print OUT "<?xml version='1.0' encoding='UTF-8'?>\n";
    print OUT "<ehr id=\"$file\">\n";

    my $first_line = 1;
    my $current_section;
    my $previous_line = "";
  
    foreach my $line (<IN>)  {   
        chomp($line);
        #print OUT "$line\n";

	# Ignore blank lines and undesired information using patterns load from file
        next if $line =~ m/$regex/;

        my ($isHeader, $header);
        $isHeader = 0;

	# Header detection
        if ($line =~ /<header>(.+)<\/header>/) { # If line is marked as possible header...
            ($isHeader, $header) = detectHeader($1);

            if (defined($header)) {
                if(defined($current_section)) { # If we are already in a section...
		    if ($current_section ne $header) { # If new section is different...
                        print OUT "\t</text>\n</Section>\n"; # Close it and start new section
			$current_section = $header;
                	$line = $header;
		    }
		    else { # If new section is the same, probably it is not a header...
                	$line = $1;
		    }
                }
            }
            else {
                $line = $1;
            }   
        }
        else { # Detect headers using list of target headers
            ($isHeader, $header) = detectHeader($line);
            if ($isHeader) { 
                if ($line =~ /^\s*(.+?)\s*:\s+(\S+)\s*/) {
                    if (defined($2)) { # If there is something after ":"...
                        ($isHeader, $header) = detectHeader($1);

                        if(defined($current_section)) { # If we are already in a section...
		            if ($current_section ne $header) { # If new section is different...
                                print OUT "\t</text>\n</Section>\n"; # Close it and start new section
			        $current_section = $header;
                	        print OUT "<Section id=\"$header\">\n\t<name id=\"$header\">$header</name>\n\t<text id=\"$header\">";	
                	        $line = $2;
				$isHeader = 0;
		            }
                        }
                    }
                }
                else {
                    if(defined($current_section)) { # If we are already in a section...
		        if ($current_section ne $header) { # If new section is different...
                            print OUT "\t</text>\n</Section>\n"; # Close it and start new section
			    $current_section = $header;	
                	    $line = $header;
		        }
                    }
                }
            }
        }
	
        # Remove extra spaces
        $line =~ s/\s+/ /g;


        # Concatenate lines if they are part of the same line
        my $current_line_size = length($line);
        if ($previous_line ne "") { # If we have something pending to print...
            if ($isHeader) {
                print OUT "\t$previous_line\n";
            }
            else {
                my $first_word = $line;
                $first_word =~ s/^\s*(.+?)\s*//g;
                $first_word = $1;
                my $first_char = substr($first_word, 0, 1);
                    
                # Check if the first word of the next lines makes line to surpass document width               
                if ( ((length($previous_line) + length($first_word)) > ($file_width*0.9)) && ($first_char ne "-")  && ($first_char ne "*")  && ($first_char ne ".") && !$isHeader) {
                    $line = $previous_line ." ". $line;
		    if ($DEBUG) { print DEBUG_LINES $previous_line ."\n\t-> ". $line ."\n\n"; }
                }
                else {
                    print OUT "\t$previous_line\n";
                }
            }
        }

	# Records may not start with a header in some hospitals
	if (defined($DEFAULT_HEADER) && $first_line && !$isHeader) { 
		$current_section = $DEFAULT_HEADER;
		print OUT "<Section id=\"$DEFAULT_HEADER\">\n\t<name id=\"$DEFAULT_HEADER\">$DEFAULT_HEADER</name>\n\t<text id=\"$DEFAULT_HEADER\">";
	}
                      
        # Print line to the XML file
        my $last_char = $line;
        $last_char =~ s/(.)\s*$//g;
        $last_char = $1;

        if ( ($current_line_size > ($file_width*0.75)) && ($last_char ne ".") && !$isHeader) { # Check if line might continue in next line
            $previous_line = $line; 
        } 
        else {
            if ($isHeader) {
		$current_section = $header;
                print OUT "<Section id=\"$header\">\n\t<name id=\"$header\">$header</name>\n\t<text id=\"$header\">";
            }
            else {
                print OUT "\t$line\n";
            }
            $previous_line = "";  
        }

	$first_line = 0; 
    }
    print OUT "\t</text>\n</Section>";
    print OUT "</ehr>";

    close(IN);
    close(OUT);
}

sub detectHeader {

    my $line = shift;
    chomp($line);
    
    my ($isHeader, $header);
    my $first_char = substr($line, 0, 1);

    if ($first_char =~ /[[:lower:]]/) {
        $isHeader = 0;
    }
    else {
        $line =~ s/\s+$//;
        if ($line =~ /:$/) { chop($line); }
        $line =~ s/\s+/ /g;
        $line = encode($enc, uc(decode($enc,$line)));

        if (defined($headers{$line})) {
            $header = $headers{$line};
            $isHeader = 1;
        }
        else {
            my ($max_sim, $max_string) = maxSimilarity($line);
            
            if ( ($max_sim >= $SIM_THRESHOLD) && (substr($line, 0, 1) ne "-")) {
                $header = $max_string;
                $isHeader = 1;

		if ($DEBUG) { print DEBUG_HEADERS $line ." => ". $header ."\n"; }
            }
            else {
		#if ($DEBUG) { print DEBUG_HEADERS $line ." !=> ". $max_string ."\n"; }
                $isHeader = 0;  
            }
        }
    }
    return ($isHeader, $header);
}

sub maxSimilarity {

    my $candicate = shift;
    
    my $max_sim = -1;
    my $max_string;
    
    foreach my $header (sort %headers) {
        my $similarity = similarity($header, $candicate);
        
        if ($similarity > $max_sim) { 
            $max_sim = $similarity; 
            $max_string = $headers{$header};
        }
    }
    
    return ($max_sim, $max_string);
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
           "dir=s",        \$ROOT_DIR,
           "sim=f",        \$SIM_THRESHOLD,
           "defheader=s",  \$DEFAULT_HEADER,
           "debug",        \$DEBUG,
           "help",         \$HELP,
           "manual",       \$MANUAL,
          );
    
    pod2usage(1) if $HELP;
    pod2usage(-verbose => 2 ) if $MANUAL;

    pod2usage if $#ARGV >0 ;

}
