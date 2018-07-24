#  Electronic Health Record (EHR) normalizer     

### Introduction
------------

  This software converts PDF files to HTML, TXT or XML. It  uses 
PDFMiner to process PDF files and convert them into HTML files with 
exact layout, and then it can convert these HTML files into TXT or 
XML. 

  Additionally, the script can detect headers from clinical records 
and restore lines that has been truncated by a previous PDF conversion.
 

### Prerequisites
-------------

  This software requires PDFMiner installed on your system (included in 
resources).


### Directory structure
-------------------

data/

  This folder contains relevant information for the conversion process:
	
  headers.txt
	This file contains a list of allowed headers for your clinical 
	records.The normalizer tries to match detected headers candidates 
	to this list.

	
  subheaders.txt
	This file contains a list of allowed subheaders for your clinical 
	records.The normalizer tries to match detected headers candidates 
	to this list. This functionality is not implemente yet.

	
  patterns-to-remove.txt
	This file contains a list of regex patterns that you want to remove
	from for your clinical records (e.x: privacy notes).


documents/

  Default root directory of source PDF files. Is mandatory to place all 
your PDF files inside a "PDF" folder. Your "PDF" folder can contain other 
sub-directories. You can also use your our root folder using command-line
argument.


resources/

  This folder contains PDFMiner. PDFMiner must be installed in your
system. If you want to use other software to convert from PDF to HTML
or TXT you must change pdf-to-html.pl script to update the call to
PDFMiner.


scripts/

  This folder contains the scripts to perform partial convertions. These
script can also be used individually.
 

### Usage
-----

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


### Examples
--------

  The following are examples of this script:

   $ convertPDF.pl --input TXT
   $ convertPDF.pl --input HTML --output TXT --sim 0.78
   $ convertPDF.pl --input PDF --output XML (does this by default)
   $ convertPDF.pl --useformat
   $ convertPDF.pl --headers --useformat
   $ convertPDF.pl --dir /home/user/my-root-dir/

  Note: Place all PDF files inside a "PDF/" directory of your root
directory.



### Author
------

 Aitor Gonzalez-Agirre
 --
 aitor.gonzalezagirre@gmail.com



### License
-------

TBD

