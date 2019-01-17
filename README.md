# EHR-normalizer: Electronic Health Record (EHR) normalizer     


## Introduction
------------

This software converts PDF files into HTML, TXT or XML files. It makes use of 
PDFMiner to process PDF files and to convert them into HTML files, retaining the 
exact layout of the documents, and then it can convert these HTML files into TXT 
or XML files according to the options chosen by the user.

Additionally, the script can perform EHR normalization by detecting headers from
documents and mapping those sections into any desired archetype. It can also restore
the lines that have been truncated by a previous conversion process from the original
document to PDF.

Covered languages: Spanish and Catalan.


## Prerequisites
-------------

This software requires to have PDFMiner installed on your system. Note that PDFMiner 
is distributed under its own license.


## Directory structure
-------------------

<pre>
data/
This folder contains relevant information for the conversion process:

  - headers.txt. This file contains a list of allowed headers for your EHRs. The 
  normalizer tries to match detected header candidates to this list.
	
  - subheaders.txt. This file contains a list of allowed subheaders for your EHRs.
  The normalizer tries to match detected header candidates to this list. This 
  functionality is not implemented yet.

  - patterns-to-remove.txt. This file contains a list of RegEx patterns that you 
  want to remove from for your EHRs (e.g. privacy notes).

documents/
Default root folder of source PDF files. It is mandatory to place all your PDF
files inside a "PDF" folder. Your "PDF" folder can contain other sub-directories. 
You can also use your our root folder using command-line arguments.

Output HTML, TXT and XML files are stored in this folder under the automatically
generated HTML, TXT or XML folders.

resources/
This folder contains PDFMiner, which must be installed in your system. If 
you want to use another software to convert from PDF to HTML or TXT, you must 
change the script pdf-to-html.pl to call the software you want to use.

scripts/
This folder contains the scripts needed to perform partial convertions. These
scripts can also be used individually.
</pre> 


## Usage
-----

It is possible to configure the behavior of this software using the different options.

  - The input and output format options allows to perform only part of the conversion. 
  This is useful if your input files are already in TXT format or if you do not need 
  to convert them to XML.
  
  - The sim parameter allows to define the tolerance when detecting headers. A lower 
  similarity will have a higher recall but a lower precision.
  
  - The defheader parameter allows to define a string that will be the header of the 
  first section if a header is not detected at the beginning of the EHR. This is useful 
  if your documents usually start without a header.
  
  - The header parameter controls whether EHR-normalizer will use format information to 
  detect the headers (text size, underlined text, etc.).
  
  - The useformat parameter controls whether EHR-normalizer will use format information 
  to detect text with different characteristics that are not part of the report (privacy 
  information, page footings, etc.).

The user can select the different options using the command line:

	convertPDF.pl [options] 

Options:
<pre>
--input format      Input format: PDF, HTML or TXT (Default: PDF).
--output format     Output format: HTML, TXT or XML (Default: XML).
--sim number        Similarity threshold for header detection (Default: 0.75).
--defheader string  Default header if first line is not a header (Default: DEFAULT_HEADER).
--headers           Use format information to identify possible headers (Default: Deactivated).
--useformat         Use format information to identify other characteristics (Default: Deactivated).
--dir               Set root directory for your documents (Default: Documents/).	
--help              Show this scripts help information.
--manual            Read this scripts manual.
</pre>


## Examples
--------

<pre>
$ ./convertPDF.pl --input TXT
$ ./convertPDF.pl --input HTML --output TXT --sim 0.78
$ ./convertPDF.pl --useformat
$ ./convertPDF.pl --headers --useformat
$ ./convertPDF.pl --dir /home/user/my-root-dir/
</pre>


## Contact
------

Aitor Gonzalez-Agirre (aitor.gonzalez@bsc.es)


## License
-------

Copyright (c) 2017-2018 Secretaría de Estado para el Avance Digital (SEAD)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

