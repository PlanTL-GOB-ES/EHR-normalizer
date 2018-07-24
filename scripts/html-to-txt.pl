#!/usr/bin/perl
#
# Usage: 
# 
#   html-to-txt.pl [options] 
#
#

=head1 NAME

html-to-txt - An script to convert HTML files into TXT files.

=head1 SYNOPSIS

 html-to-txt.pl [options] 

  Help Options:
   --dir directory     Use another root directory.
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

   $ html-to-txt.pl
   $ html-to-txt.pl --useformat
   $ html-to-txt.pl --headers --useformat
   $ html-to-txt.pl --dir /home/user/my-root-dir/

  Note: Place all HTML files inside a "HTML/" directory of your root
 directory.

=cut


=head1 DESCRIPTION

  This script transforms HTML files generated from PDF files using PDFMiner 
 into TXT files.

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
use POSIX;
use Math::Round;

# Default directory
my $ROOT_DIR = "../documents";

# Use format information to identify posisible headers and privacy information.
my $DETECT_HEADERS = 0;
my $USE_FORMAT = 0;

# In HTML files generated from PDF some characters may vary in their top position
# by some pixels. We join all characters in the same line using a tolerance
my $TOP_TOLERANCE = 3; 

# Parse command line arguments.
parseCommandLineArguments();


## Process HTML files
processHTML("$ROOT_DIR/HTML");


################################
######### SUB-ROUTINES #########
################################

# Accepts one argument: the full path to a custom directory.
# Returns: nothing.
sub processHTML {
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
    (my $target_path = $path) =~ s/HTML/TXT/g;
    mkdir $target_path unless -d $target_path;

    # Start processing files
    print "Processing \'$path\/\'...\n";

    foreach my $source (sort @files) {

	($target_path = $source) =~ s/HTML/TXT/g;

        # If the file is a directory
        if (-d $source) {
            # Here where we recurse if we found a sub-directory
            # Create target sub-directory if it does not exist
            mkdir $target_path unless -d $target_path;

	    # Process files
            processHTML ($source);        
        }
	# If it is a file, process it
	else {

            # Load HTML file into Hash
            my %html = loadHTML($source);
            
            # Print from Hash to TXT file
            printToTXT(\%html, "$target_path.txt");
        }
	
    }    
}

sub loadHTML {

    my $file = shift;
    
    my %html;
    
    open(IN, $file) or die("Could not open file.");

    foreach my $line (<IN>)  {   
        chomp($line);

        # Check if line is an underline: possible header
        my $underline = $line;

        if ($underline =~ /<span style="position:absolute; border: black 1px solid; left:(.+)px; top:(.+)px; width:(.+)px; height:(.+)px;"><\/span>/) {
            # Load object position         
	    my ($underline_left, $underline_top, $underline_width, $underline_height);

            $underline_left =  $1;
            $underline_top =  $2;
            $underline_width = $3;
            $underline_height =  $4;
	    
            if (defined($underline_top) && defined($underline_left) && defined($underline_width)) {
	    	$html{"underline"}->{$underline_top} = ($underline_left+$underline_width); # Mark it as possible header (
	    }	
	}
        
        # Continue processing
        if ($line =~ /<span style="position:absolute; color:(.+); left:(.+)px; top:(.+)px; font-size:(.+)px;">(.*)<\/span>/) {

            # Load object characteristics
	    my ($color, $left, $top, $size, $char);

            $color = $1;
            $left = $2;
            $top = $3;
            $size = $4;
            $char = $5;
            
            if (defined($char)) {
                if ($left eq "black") { warn "ERROR: Something is wrong in line: $line\n"; }

                # In HTML files characters of the same line may be on different top positions
                # We wrap them together
		for (my $i=(-1*$TOP_TOLERANCE); $i <= $TOP_TOLERANCE; $i++) {
		    if (defined($html{"lines"}->{$top+$i})) {
                    	$top = $top + $i;
			last;
                    }
		}
                
		# Check if we are overwriting a char already stored in a given position (PDFMiner does this).
		# If so, warn user, then store character.
                if (defined($html{"lines"}->{$top}->{$left}->{"char"})) {
                    warn "WARNING! Trying to overwrite \'". $html{"lines"}->{$top}->{$left}->{"char"} ."\' with \'$char\' (both characters share the same position): file $file\n";
                    if ( ($char ne "" && $char ne " ") && ($html{"lines"}->{$top}->{$left}->{"char"} eq " ") ) { # Whitespaces are less important characters
                        $html{"lines"}->{$top}->{$left}->{"char"} = $char;
                    }
                }
                else {
                    $html{"lines"}->{$top}->{$left}->{"char"} = $char;
                }
                $html{"lines"}->{$top}->{$left}->{"size"} = $size;
                $html{"lines"}->{$top}->{$left}->{"color"} = $color;
            }
        }      
    }
    close(IN);
    
    return %html;
}

            
sub printToTXT {

    my %html = %{$_[0]};
    my $file = $_[1];
    
    open(OUT, ">$file") or die("Could not open file: $file.");
    
    my $line= "";
    my ($old_color, $old_left, $old_top, $old_size);
    my $is_header;
    my ($file_min_left,$file_max_left,$file_min_size,$file_max_size,$file_avg_size) = getStats(\%html);

    # Look if underlining are attached to possible headers (if line is not width enough it may be a header )
    foreach my $underline_top (sort {$a <=> $b} keys %{$html{"underline"}}) {
        if (abs($html{"underline"}->{$underline_top} - $file_max_left) > 20) { # If underlining is different enough of document width
             $html{"headers"}->{$underline_top} = 1; # Mark it as possible underlining of header
        }
    }
    
    # Start printing to text, starting from the first line (lowest top values).
    foreach my $top (sort {$a <=> $b} keys %{$html{"lines"}}) {
    
        undef $is_header;

	# Write line from leftmost to rightmost
        foreach my $left (sort {$a <=> $b} keys %{$html{"lines"}->{$top}}) {

            if (defined($html{"lines"}->{$top}->{$left}->{"char"})) {
            
                my $char = $html{"lines"}->{$top}->{$left}->{"char"};  
                my $size = $html{"lines"}->{$top}->{$left}->{"size"};
                
                
		# Use format to detect headers characteristics
		if ($DETECT_HEADERS) {
			# Check format to detect possible headers	
		        if (!defined($is_header)) {
		            if ($size > ($file_avg_size+1)) { # At least 2 px larger than average text size
		                $is_header = 1;
		            }
		            else { # For underlined text...
				# For each underline that is not width enough...
		                foreach my $header_candidate (sort {$a<=>$b} keys %{$html{"headers"}}) {
				    # Check is current line is one line above the underline
		                    if ( ( ($header_candidate-$top) <= ($file_avg_size+1)) && ( ($header_candidate-$top) > ($file_avg_size-2) ) ) {
		                        $is_header = 1; # This line is underlined, mark it as header.
		                    }
		                }
		                
		            }
		        }
		}

		# Use format to detect characteristics	
                if ($USE_FORMAT) {
		        # Next if privacy notes or noise
		        next if $size < $file_avg_size; # Do not print if size is smaller than average
                }

                # If first character of the line...
                if (!defined($old_left)) { $old_left = $left; }
                if (!defined($old_top)) { $old_top = $top; }
                if (!defined($old_size)) { $old_size = $size; }
        
                
		# Check if char is part of the previous word, new one, etc...
                if (($left-$old_left < $size+2) && $top-$old_top < 1) { # Same word or first word
                    $line = $line . $char;
                    $old_left = $left;
                    $old_top = $top;
                    $old_size = $size;
                }
                elsif ($left-$old_left < 160 && $top-$old_top < 3) { # Related (Word in the same line, but more separated than usual)
		    # No difference with previous, but we can use this to detect tables and other phenomena
                    $line = $line . $char;
                    $old_left = $left;
                    $old_top = $top;
                    $old_size = $size;
                }
            }	
        }
	#End of line

        # Remove extra spaces
        $line =~ s/\s+/ /g;
                    
        if (defined($is_header) && $DETECT_HEADERS) {
            if ($line !~ /^\s*$/) { # If non-empty line
                print OUT "<header>$line</header>\n";
            }

        }
        else {
            if ($line !~ /^\s*$/) { # If non-empty line
                print OUT "$line\n";
            }
        }

        $line = "";
	undef $old_left;
	undef $old_top;
	undef $old_size;
    }
    close(OUT);
}

sub getStats {

    my %html = %{$_[0]};
    
    my $file_avg_size = 0;  
    my ($file_min_left, $file_max_left, $file_min_size, $file_max_size);
    my $total = 0;

    foreach my $top (sort {$a <=> $b} keys %{$html{"lines"}}) {

        foreach my $left (sort {$a <=> $b} keys %{$html{"lines"}->{$top}}) {

                my $size = $html{"lines"}->{$top}->{$left}->{"size"};

		if(defined($file_min_left)) { if($left < $file_min_left) { $file_min_left = $left; } }	else {$file_min_left = $left; }
		if(defined($file_max_left)) { if($left > $file_max_left) { $file_max_left = $left; } }	else {$file_max_left = $left; }

		if(defined($file_min_size)) { if($size < $file_min_size) { $file_min_size = $size; } }	else {$file_min_size = $size; }
		if(defined($file_max_size)) { if($size > $file_max_size) { $file_max_size = $size; } }	else {$file_max_size = $size; }
 
		$file_avg_size = $file_avg_size + $size;
		$total++;
        }
    }
    $file_avg_size = round($file_avg_size/$total);

    return ($file_min_left,$file_max_left,$file_min_size,$file_max_size,$file_avg_size);
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
           "dir=s",  	  \$ROOT_DIR,
           "headers",     \$DETECT_HEADERS,
           "useformat",   \$USE_FORMAT,
           "help",   	  \$HELP,
           "manual", 	  \$MANUAL,
          );
    
    pod2usage(1) if $HELP;
    pod2usage(-verbose => 2 ) if $MANUAL;

    pod2usage if $#ARGV >0 ;

}

