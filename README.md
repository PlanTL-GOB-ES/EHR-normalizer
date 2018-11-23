# EHR-normalizer: Electronic Health Record (EHR) normalizer     


##  Digital Object Identifier (DOI)

https://doi.org/10.5281/zenodo.1492657


## Introduction
------------

This software converts PDF files into HTML, TXT or XML files. First, it uses PDFMiner 
to process PDF files and to convert them into HTML files, retaining the 
exact layout of the documents, and then it converts these HTML files into TXT or 
XML files. 

Additionally, the script can detect headers from EHRs and restore those lines 
that have been truncated by a previous PDF conversion process.

Language covered: Spanish and Catalan.


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
$ convertPDF.pl --input TXT
$ convertPDF.pl --input HTML --output TXT --sim 0.78
$ convertPDF.pl --input PDF --output XML (does this by default)
$ convertPDF.pl --useformat
$ convertPDF.pl --headers --useformat
$ convertPDF.pl --dir /home/user/my-root-dir/
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

