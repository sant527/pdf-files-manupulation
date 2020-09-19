   * [COMBINE LARGE PDFS USING STAPLER](#combine-large-pdfs-using-stapler)
      * [Customize Stapler to be more verbose while combine large pdfs](#customize-stapler-to-be-more-verbose-while-combine-large-pdfs)
         * [MODIFY SOURCE CODE OF STAPLER**](#modify-source-code-of-stapler)
         * [MODIFY SOURCE CODE OF PyPDF2 python2**](#modify-source-code-of-pypdf2-python2)
         * [AFTER CHANGES THE OUTPUT OF STAPLER WILL BE**](#after-changes-the-output-of-stapler-will-be)
   * [Changes in source code of PyPDF2 for python3 for output to be more verbose:](#changes-in-source-code-of-pypdf2-for-python3-for-output-to-be-more-verbose)
   * [IMPORT AND EXPORT TOC FOR LARGE PDFS](#import-and-export-toc-for-large-pdfs)
      * [pdftk fails](#pdftk-fails)
      * [STEP1: Extract the bookmarks of large pdf](#step1-extract-the-bookmarks-of-large-pdf)
         * [STEP1A: Use mupdf to get into the flatten format**](#step1a-use-mupdf-to-get-into-the-flatten-format)
         * [STEP1B: Convert toc from flatten format to the format of PyPDF2 (i.e nested array)](#step1b-convert-toc-from-flatten-format-to-the-format-of-pypdf2-ie-nested-array)
      * [STEP2: IMPORT/PUT the bookmars from nested_array into the pdf](#step2-importput-the-bookmars-from-nested_array-into-the-pdf)
   * [Combining toc of multiple pdfs](#combining-toc-of-multiple-pdfs)
      * [STEP1: Combine the pdfs using stapler**](#step1-combine-the-pdfs-using-stapler)
      * [STEP2: Get the combined nested toc/outline python array**](#step2-get-the-combined-nested-tocoutline-python-array)
      * [STEP3: Using Combined.pdf and Total nested array of outline create Combined.pdf with toc**](#step3-using-combinedpdf-and-total-nested-array-of-outline-create-combinedpdf-with-toc)
   * [COMBINED CODE FOR MULTIPLE PDFS WITH TOC](#combined-code-for-multiple-pdfs-with-toc)
      * [SEPERATE](#seperate)
      * [AS BASH FILE](#as-bash-file)
   * [Adding boomarks using mupdf without PyPDF2](#adding-boomarks-using-mupdf-without-pypdf2)
      * [STEP1: Combine the pdfs using stalpler](#step1-combine-the-pdfs-using-stalpler)
      * [STEP2: Club the toc of the files used for creating Combined.pdf](#step2-club-the-toc-of-the-files-used-for-creating-combinedpdf)
      * [STEP3: ADD THE TOTAL OUTLINES TO THE Combined.pdf](#step3-add-the-total-outlines-to-the-combinedpdf)
   * [Combining the code for mupdf toc](#combining-the-code-for-mupdf-toc)
   * [Changes to be made in the source code of Mupdf setTOC](#changes-to-be-made-in-the-source-code-of-mupdf-settoc)
# COMBINE LARGE PDFS USING STAPLER
## Customize Stapler to be more verbose while combine large pdfs

Stapler uses python2

**BASH COMMAND**
```bash
# stapler --verbose cat File1.pdf File2.pdf File3.pdf File4.pdf ALL.pdf
```
We want to club pdfs of each size 15000+ pages. So we want to see some indication while the pdfs are getting clubbed
So use `--verbose`

But `--verbose is not just sufficient` we want to see more indication whats happening. So do the following changes in the following files

### MODIFY SOURCE CODE OF STAPLER**

`/usr/lib/python2.7/site-packages/staplelib/commands.py`
```python
def select(args, inverse=False):
    """
    Concatenate files / select pages from files.

    inverse=True excludes rather than includes the selected pages from
    the file.
    """

    #--------------------------------------------
            for pageno, rotate in pagerange:
                if 1 <= pageno <= pdf.getNumPages():
                    if verbose:
                        #----------------------LINE CHANGED--------------
                        #----------------------ADDED File name also------
                        print "File: {} Using page: {} (rotation: {} deg.)".format(input['name'],
                            pageno, rotate)
                        #----------------------LINE CHANGED--------------

                    output.addPage(pdf.getPage(pageno-1)
                                   .rotateClockwise(rotate))
                else:
                    raise CommandError("Page {} not found in {}.".format(
                        pageno, input['name']))
    #--------------------------------------------
```
### MODIFY SOURCE CODE OF PyPDF2 python2**

Stapler uses python 2 libraries

To find out the location of PyPDF2 in python2 do the following
```
$ python2
Python 2.7.16 (default, Mar 11 2019, 18:59:25) 
[GCC 8.2.1 20181127] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> import PyPDF2
>>> PyPDF2.__file__
'/usr/lib/python2.7/site-packages/PyPDF2/__init__.py'
>>> 
```

`/usr/lib/python2.7/site-packages/PyPDF2/pdf.py`
```python
    def write(self, stream):

        #----------ADDED PRINT------------------------
        for objIndex in range(len(self._objects)):
            obj = self._objects[objIndex]
            print str(objIndex)+"/"+str(len(self._objects))+" :: def write: for objIndex in range(len(self._objects)): "
            if isinstance(obj, PageObject) and obj.indirectRef != None:
                data = obj.indirectRef
                if data.pdf not in externalReferenceMap:
                    externalReferenceMap[data.pdf] = {}
                if data.generation not in externalReferenceMap[data.pdf]:
                    externalReferenceMap[data.pdf][data.generation] = {}
                externalReferenceMap[data.pdf][data.generation][data.idnum] = IndirectObject(objIndex + 1, 0, self)
        #---------------------------------------------

        self.stack = []
        print "self.stack = []"
        if debug: print(("ERM:", externalReferenceMap, "root:", self._root))
        print "if debug: print((\"ERM:\", externalReferenceMap, \"root:\", self._root))"

        #--------------ADDED A NEW VARIABLE WHICH WILL BE USED IN _sweepIndirectReferences------------------------
        self.gauranga = 0
        self._sweepIndirectReferences(externalReferenceMap, self._root)
        self.gauranga = 0
        #--------------------------------------------------------------
        del self.stack
        print "del self.stack"

        # Begin writing:
        print "str(self._header): "+str(self._header)
        object_positions = []
        stream.write(self._header + b_("\n"))

        #--------------ADDED PRINT---------------------------------------------
        for i in range(len(self._objects)):
            idnum = (i + 1)
            obj = self._objects[i]
            object_positions.append(stream.tell())
            stream.write(b_(str(idnum) + " 0 obj\n"))
            key = None
            if hasattr(self, "_encrypt") and idnum != self._encrypt.idnum:
                pack1 = struct.pack("<i", i + 1)[:3]
                pack2 = struct.pack("<i", 0)[:2]
                key = self._encrypt_key + pack1 + pack2
                assert len(key) == (len(self._encrypt_key) + 5)
                md5_hash = md5(key).digest()
                key = md5_hash[:min(16, len(self._encrypt_key) + 5)]
            obj.writeToStream(stream, key)
            if i % 1000 == 0:
                print str(i)+" / "+str(len(self._objects))+"for i in range(len(self._objects)):: "
            stream.write(b_("\nendobj\n"))
        #---------------------------------------------
```


`/usr/lib/python2.7/site-packages/PyPDF2/pdf.py`
```python
    def _sweepIndirectReferences(self, externMap, data):
        self.gauranga = self.gauranga + 1
        if self.gauranga % 10000 == 0:
            print str(self.gauranga)+" :self.gauranga: def _sweepIndirectReferences(self, externMap, data)"
        debug = False
        if debug: print((data, "TYPE", data.__class__.__name__))
```

### AFTER CHANGES THE OUTPUT OF STAPLER WILL BE**
```bash
# stapler --verbose cat File1.pdf File2.pdf File3.pdf File4.pdf ALL.pdf
File: File1.pdf Using page: 13489 (rotation: 0 deg.)
File: File1.pdf Using page: 13490 (rotation: 0 deg.)
File: File1.pdf Using page: 13491 (rotation: 0 deg.)
File: File1.pdf Using page: 13492 (rotation: 0 deg.)
File: File1.pdf Using page: 13493 (rotation: 0 deg.)
...
52351/52358 :: def write: for objIndex in range(len(self._objects)): 
52352/52358 :: def write: for objIndex in range(len(self._objects)): 
52353/52358 :: def write: for objIndex in range(len(self._objects)): 
52354/52358 :: def write: for objIndex in range(len(self._objects)): 
52355/52358 :: def write: for objIndex in range(len(self._objects)): 
52356/52358 :: def write: for objIndex in range(len(self._objects)): 
52357/52358 :: def write: for objIndex in range(len(self._objects)): 
...
10000 :self.gauranga: def _sweepIndirectReferences(self, externMap, data)
20000 :self.gauranga: def _sweepIndirectReferences(self, externMap, data)
30000 :self.gauranga: def _sweepIndirectReferences(self, externMap, data)
40000 :self.gauranga: def _sweepIndirectReferences(self, externMap, data)
50000 :self.gauranga: def _sweepIndirectReferences(self, externMap, data)
60000 :self.gauranga: def _sweepIndirectReferences(self, externMap, data)
70000 :self.gauranga: def _sweepIndirectReferences(self, externMap, data)
....
47000 / 52358for i in range(len(self._objects)):: 
48000 / 52358for i in range(len(self._objects)):: 
49000 / 52358for i in range(len(self._objects)):: 
50000 / 52358for i in range(len(self._objects)):: 
51000 / 52358for i in range(len(self._objects)):: 
52000 / 52358for i in range(len(self._objects)):: 

```

# Changes in source code of PyPDF2 for python3 for output to be more verbose:

generally Py2PDF library is used as

```python
from PyPDF2 import PdfFileWriter, PdfFileReader
output = PdfFileWriter()
# .. do some filreading and adding pages and bookmarks to output
outputfile = open(outputfile.pdf, 'wb')
output.write(outputfile)
```

we want to see the output.write to be more verbose

Note: We have done changes in PyPDF of python2 i.e at '/usr/lib/python2.7/site-packages/PyPDF2/__init__.py'

Now here we have to do the same in PyPDF of python3 i.e at '/usr/lib/python3.7/site-packages/PyPDF2/__init__.py'

To the get the path of PyPdf2 in python do
```
$ python
Python 3.7.3 (default, Mar 26 2019, 21:43:19) 
[GCC 8.2.1 20181127] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import PyPDF2
>>> PyPDF2.__file__
'/usr/lib/python3.7/site-packages/PyPDF2/__init__.py'
>>> 
```

Because the `import PyPDF2` in default python files will be to '/usr/lib/python3.7/site-packages/PyPDF2/__init__.py'


`/usr/lib/python3.7/site-packages/PyPDF2/pdf.py`
```python
    def addBookmark(self, title, pagenum, parent=None, color=None, bold=False, italic=False, fit='/Fit', *args):
        #----------ADD PRINT---------------------------
        print(str(pagenum)+" :: pagenum :: def addBookmark")
        #--------------------------------------------
        pageRef = self.getObject(self._pages)['/Kids'][pagenum]
        action = DictionaryObject()
        zoomArgs = []
        for a in args:
```

```python
    def _sweepIndirectReferences(self, externMap, data):
        self.gauranga = self.gauranga + 1
        if self.gauranga % 10000 == 0:
            print(str(self.gauranga)+" : def _sweepIndirectReferences(self, externMap, data)")
        debug = False
```

```python
        for objIndex in range(len(self._objects)):
            obj = self._objects[objIndex]
            #-----------CHANGED---------------------------------------
            print(str(objIndex)+"/"+str(len(self._objects))+" :: def write: for objIndex in range(len(self._objects)): ")
            #----------------------------------------------------------
            if isinstance(obj, PageObject) and obj.indirectRef != None:
                data = obj.indirectRef
                if data.pdf not in externalReferenceMap:
                    externalReferenceMap[data.pdf] = {}
                if data.generation not in externalReferenceMap[data.pdf]:
                    externalReferenceMap[data.pdf][data.generation] = {}
                externalReferenceMap[data.pdf][data.generation][data.idnum] = IndirectObject(objIndex + 1, 0, self)

        self.stack = []
        if debug: print(("ERM:", externalReferenceMap, "root:", self._root))
        #-----------CHANGED---------------------------------------
        self.gauranga = 0
        self._sweepIndirectReferences(externalReferenceMap, self._root)
        self.gauranga = 0
        #----------------------------------------------------------
        del self.stack

        # Begin writing:
        object_positions = []
        stream.write(self._header + b_("\n"))
        for i in range(len(self._objects)):
            idnum = (i + 1)
            obj = self._objects[i]
            object_positions.append(stream.tell())
            stream.write(b_(str(idnum) + " 0 obj\n"))
            key = None
            if hasattr(self, "_encrypt") and idnum != self._encrypt.idnum:
                pack1 = struct.pack("<i", i + 1)[:3]
                pack2 = struct.pack("<i", 0)[:2]
                key = self._encrypt_key + pack1 + pack2
                assert len(key) == (len(self._encrypt_key) + 5)
                md5_hash = md5(key).digest()
                key = md5_hash[:min(16, len(self._encrypt_key) + 5)]
            obj.writeToStream(stream, key)
            #-----------CHANGED---------------------------------------
            if i % 1000 == 0:
                print(str(i)+" / "+str(len(self._objects))+"def write: for i in range(len(self._objects)):: ")
            #---------------------------------------------------
            stream.write(b_("\nendobj\n"))
```

# IMPORT AND EXPORT TOC FOR LARGE PDFS

**Requirement**
We have PDF of 1.8 lakh pages and with toc/outlines of 50k entries. we want to extract the toc, do some changes and again import them back into the pdf

## pdftk fails
Tried to do this with pdftk it keeps failing saying increase GC_MAXIMUM_HEAP_SIZE/MAX_HEAP_SECTS
I tried with
```
# export GC_MAXIMUM_HEAP_SIZE=$(( 150 * (1024) * (1024) * (1024) ))
# export MAX_HEAP_SECTS=$(( 100 * (1024) * (1024) * (1024) ))
# pdftk verylarge.pdf dump_data output all_toc.txt
Too many heap sections: Increase MAXHINCR or MAX_HEAP_SECTS
```
We will use mupdf to get the large pdfs TOC or to combine multiple pdfs toc

***Note***: For small pdfs use pdftk only no need for the below procedure

## STEP1: Extract the bookmarks of large pdf

### STEP1A: Use mupdf to get into the flatten format**
So we will use mupdf's fitz library for this
Install mupdf using AUR

Using mupdf we will get the toc in the format
```
hare = [
    {"/Page": "0","/Title": "title000","/Type": "/Fit","level": 1},
    {"/Page": "0","/Title": "title000","/Type": "/Fit","level": 1},
    {"/Page": "1","/Title": "title001","/Type": "/Fit","level": 2},
    {"/Page": "3","/Title": "title008","/Type": "/Fit","level": 3},
    {"/Page": "6","/Title": "title006","/Type": "/Fit","level": 4},
    {"/Page": "2","/Title": "title002","/Type": "/Fit","level": 2},
    {"/Page": "3","/Title": "title008","/Type": "/Fit","level": 3},
    {"/Page": "6","/Title": "title006","/Type": "/Fit","level": 4},
    {"/Page": "7","/Title": "title007","/Type": "/Fit","level": 4},
    {"/Page": "0","/Title": "title000","/Type": "/Fit","level": 1},
    {"/Page": "1","/Title": "title001","/Type": "/Fit","level": 2},
    {"/Page": "2","/Title": "title002","/Type": "/Fit","level": 2}
]
```

```python
import fitz
filename="verylarge.pdf"
doc = fitz.open(filename)  # open file
toc = doc.getToC(False) # its table of contents (list)
# [ [level,Title,Pagenum],[level,Title,Pagenum] .....]
pc = len(doc)  # number of its pages

new_format=[]
for line in toc:  # read toc 
    new_format.append({"/Page": line[2],"/Title": line[1],"/Type": "/Fit","level": line[0]})

print(new_format)
```


### STEP1B: Convert toc from flatten format to the format of PyPDF2 (i.e nested array)

We want to convert the mupdf toc output the below nested array output
```
[
    {
        "/Page": "0",
        "/Title": "title000",
        "/Type": "/Fit"
    },
    {
        "/Page": "0",
        "/Title": "title000",
        "/Type": "/Fit"
    },
    [
        {
            "/Page": "1",
            "/Title": "title001",
            "/Type": "/Fit"
        },
        [
            {
                "/Page": "3",
                "/Title": "title008",
                "/Type": "/Fit"
            },
            [
                {
                    "/Page": "6",
                    "/Title": "title006",
                    "/Type": "/Fit"
                }
            ]
        ],
        {
            "/Page": "2",
            "/Title": "title002",
            "/Type": "/Fit"
        },
        [
            {
                "/Page": "3",
                "/Title": "title008",
                "/Type": "/Fit"
            },
            [
                {
                    "/Page": "6",
                    "/Title": "title006",
                    "/Type": "/Fit"
                },
                {
                    "/Page": "7",
                    "/Title": "title007",
                    "/Type": "/Fit"
                }
            ]
        ]
    ],
    {
        "/Page": "0",
        "/Title": "title000",
        "/Type": "/Fit"
    },
    [
        {
            "/Page": "1",
            "/Title": "title001",
            "/Type": "/Fit"
        },
        {
            "/Page": "2",
            "/Title": "title002",
            "/Type": "/Fit"
        }
    ]
]
```

Combining with mupdf code:

```python
import fitz
filename="verylargefile.pdf"
doc = fitz.open(filename)  # open file
toc_mu = doc.getToC(False) # its table of contents (list)
# [ [level,Title,Pagenum],[level,Title,Pagenum] .....]
pc = len(doc)  # number of its pages

new_format=[]
for line in toc_mu:  # read toc 
    new_format.append({"/Page": line[2],"/Title": line[1],"/Type": "/Fit","level": line[0]})

print(new_format)

### PART2 CONVERT FLATTEN TOC FROM MUPDF TO NESTED FORMAR OF PYPDF2
toc = new_format.copy()

toclen = len(toc)

nested_array=[]
for i in range(toclen):
    o = toc[i]
    n=toc[i]["level"]
    #print("n=toc[i][\"level\"]:: i,n ::"+str(i)+","+str(n))
    index=""
    arr1 = None
    for j in range(0,n):
        #print("i,j ::::"+str(i)+","+str(j))
        if arr1 is None:
            arr1 = nested_array
        else:
            len_arr1 = len(arr1)
            if isinstance(arr1[len_arr1-1], list):
                arr1=arr1[len_arr1-1]
            else:
                arr1.append([])
                len_arr1 = len(arr1)
                arr1=arr1[len_arr1-1]
    arr1.append(o)

import json
print("nested_array == "+json.dumps(nested_array, indent=4, sort_keys=True, default=str))
```

## STEP2: IMPORT/PUT the bookmars from nested_array into the pdf

```python
### PART3 IMPORTING THE BOOKMARKS

from PyPDF2 import PdfFileWriter, PdfFileReader

output = PdfFileWriter()
input1 = PdfFileReader(open(filename, 'rb'))

for pageno in range(input1.getNumPages()):
    print("(Using page: "+str(pageno+1)+")")
    output.addPage(input1.getPage(pageno-1))

def _write_bookmarks(bookmarks=None, parent=None):
    last_added = None
    for b in bookmarks:
        if isinstance(b, list):
            _write_bookmarks(b, last_added)
            continue
        last_added = output.addBookmark(b["/Title"], b["/Page"]-1,parent)

_write_bookmarks(nested_array)

# get filename from filename.pdf
# os.path.splitext(filename)[0]

#get .pdf from filename.pdf
# os.path.splitext(filename)[1]

import os
outputfile = open(os.path.splitext(filename)[0]+"_indexed"+os.path.splitext(filename)[1], 'wb')
output.write(outputfile)
```

**COMBINED**
```python
import fitz
filename="Adi_index.pdf"
doc = fitz.open(filename)  # open file
toc_mu = doc.getToC(False) # its table of contents (list)
# [ [level,Title,Pagenum],[level,Title,Pagenum] .....]
pc = len(doc)  # number of its pages

new_format=[]
for line in toc_mu:  # read toc 
    new_format.append({"/Page": line[2],"/Title": line[1],"/Type": "/Fit","level": line[0]})

print(new_format)

### PART2 CONVERT FLATTEN TOC FROM MUPDF TO NESTED FORMAR OF PYPDF2
toc = new_format.copy()

toclen = len(toc)

nested_array=[]
for i in range(toclen):
    o = toc[i]
    n=toc[i]["level"]
    #print("n=toc[i][\"level\"]:: i,n ::"+str(i)+","+str(n))
    index=""
    arr1 = None
    for j in range(0,n):
        #print("i,j ::::"+str(i)+","+str(j))
        if arr1 is None:
            arr1 = nested_array
        else:
            len_arr1 = len(arr1)
            if isinstance(arr1[len_arr1-1], list):
                arr1=arr1[len_arr1-1]
            else:
                arr1.append([])
                len_arr1 = len(arr1)
                arr1=arr1[len_arr1-1]
    arr1.append(o)

import json
print("nested_array == "+json.dumps(nested_array, indent=4, sort_keys=True, default=str))


### PART3 IMPORTING THE BOOKMARKS

from PyPDF2 import PdfFileWriter, PdfFileReader

output = PdfFileWriter()
input1 = PdfFileReader(open(filename, 'rb'))

for pageno in range(input1.getNumPages()):
    print("(Using page: "+str(pageno+1)+")")
    output.addPage(input1.getPage(pageno-1))

def _write_bookmarks(bookmarks=None, parent=None):
    last_added = None
    for b in bookmarks:
        if isinstance(b, list):
            _write_bookmarks(b, last_added)
            continue
        last_added = output.addBookmark(b["/Title"], b["/Page"]-1,parent)

_write_bookmarks(nested_array)

# get filename from filename.pdf
# os.path.splitext(filename)[0]

#get .pdf from filename.pdf
# os.path.splitext(filename)[1]

import os
outputfile = open(os.path.splitext(filename)[0]+"_indexed"+os.path.splitext(filename)[1], 'wb')
output.write(outputfile)
```

# Combining toc of multiple pdfs

Use pdftk for small pdfs but for large pdfs of 1,00,000+ pages and 50k+ outlines use the below procedure

**GOAL**
Example we have `File1.pdf`, `File1.pdf`, `File3.pdf` and `File4.pdf`

Now we want a `Combined.pdf` with the `toc/outline` also combined

## STEP1: Combine the pdfs using stapler**

```bash
# stapler --verbose cat File1.pdf File2.pdf File3.pdf File4.pdf Combined.pdf
```

## STEP2: Get the combined nested toc/outline python array**

Note: Update Bookmark pagenumbers: We have to add the add up page numbers of previous files total to the bookmarks

```python
import fitz
# STEP A: GET THE FLATTENED TOTAL OUTLINES
fileslist=[
    "File1.pdf",
    "File2.pdf",
    "File3.pdf",
    "File4.pdf",
]

# combining toc and also updating the bookmark page number
outlines=[]
total_pages=0
for i in range(len(fileslist))
    doc = fitz.open(fileslist[i])  # open file
    toc = doc.getToC(False)
    new_toc=[]
    for line in toc:  # read TOC to update its page numbers
        line[2] = line[2] + total_pages  # add total page count to this page number
        new_toc.append(line)
    outlines = outlines + new_toc
    total_pages = total_pages + len(doc)

new_format=[]
for line in outlines:  # read toc 
    new_format.append({"/Page": outlines[2],"/Title": outlines[1],"/Type": "/Fit","level": outlines[0]})

print(new_format)

# STEP B: CONVERT FLATTEN TOC FROM MUPDF TO NESTED FORMAR OF PYPDF2
toc = new_format.copy()

toclen = len(toc)

nested_array=[]
for i in range(toclen):
    o = toc[i]
    n=toc[i]["level"]
    #print("n=toc[i][\"level\"]:: i,n ::"+str(i)+","+str(n))
    index=""
    arr1 = None
    for j in range(0,n):
        #print("i,j ::::"+str(i)+","+str(j))
        if arr1 is None:
            arr1 = nested_array
        else:
            len_arr1 = len(arr1)
            if isinstance(arr1[len_arr1-1], list):
                arr1=arr1[len_arr1-1]
            else:
                arr1.append([])
                len_arr1 = len(arr1)
                arr1=arr1[len_arr1-1]
    arr1.append(o)

import json
print("nested_array == "+json.dumps(nested_array, indent=4, sort_keys=True, default=str))
```

## STEP3: Using Combined.pdf and Total nested array of outline create Combined.pdf with toc**

```python
from PyPDF2 import PdfFileWriter, PdfFileReader
combinedfile="Combined.pdf"
output = PdfFileWriter()
input1 = PdfFileReader(open(combinedfile, 'rb'))

for pageno in range(input1.getNumPages()):
    print("(Using page: "+str(pageno+1)+")")
    output.addPage(input1.getPage(pageno-1))

def _write_bookmarks(bookmarks=None, parent=None):
    last_added = None
    for b in bookmarks:
        if isinstance(b, list):
            _write_bookmarks(b, last_added)
            continue
        last_added = output.addBookmark(b["/Title"], b["/Page"]-1,parent)

_write_bookmarks(nested_array)

# get filename from combinedfile.pdf
# os.path.splitext(combinedfile)[0]

#get (ext).pdf from combinedfile.pdf
# os.path.splitext(combinedfile)[1]

import os
outputfile = open(os.path.splitext(combinedfile)[0]+"_indexed"+os.path.splitext(combinedfile)[1], 'wb')
output.write(outputfile)
```

Now we have `Combined_indexed.pdf` with the toc


# COMBINED CODE FOR MULTIPLE PDFS WITH TOC


## SEPERATE

```bash
## STEP0: Combine the pdfs using stapler**
# stapler --verbose cat File1.pdf File2.pdf File3.pdf File4.pdf Combined.pdf
```


```python
import json
import fitz
import time
# STEP A: GET THE FLATTENED TOTAL OUTLINES
fileslist=["Adi_index.pdf", "Mad1_index.pdf", "Mad2_index.pdf", "Ant_index.pdf", ]
combinedfile="Combined.pdf"

print("fileslist:: "+str(fileslist))
print("combinedfile:: "+combinedfile)

# combining toc and also updating the bookmark page number
outlines=[]
total_pages=0
for i in range(len(fileslist)):
    print("mupdf READING FILE:: "+fileslist[i])
    doc = fitz.open(fileslist[i])  # open file
    toc = doc.getToC(False)
    new_toc=[]
    for line in toc:  # read TOC to update its page numbers
        line[2] = line[2] + total_pages  # add total page count to this page number
        new_toc.append(line)
    outlines = outlines + new_toc
    total_pages = total_pages + len(doc)

new_format=[]
for line in outlines:  # read toc 
    new_format.append({"/Page": line[2],"/Title": line[1],"/Type": "/Fit","level": line[0]})

file1 = open("combined_toc_dump_flatten.txt","a")
file1.write(json.dumps(new_format, indent=4, sort_keys=True, default=str))
file1.close() 

print(new_format)

# STEP B: CONVERT FLATTEN TOC FROM MUPDF TO NESTED FORMAR OF PYPDF2
toc = new_format.copy()

toclen = len(toc)

nested_array=[]
for i in range(toclen):
    o = toc[i]
    n=toc[i]["level"]
    #print("n=toc[i][\"level\"]:: i,n ::"+str(i)+","+str(n))
    index=""
    arr1 = None
    for j in range(0,n):
        #print("i,j ::::"+str(i)+","+str(j))
        if arr1 is None:
            arr1 = nested_array
        else:
            len_arr1 = len(arr1)
            if isinstance(arr1[len_arr1-1], list):
                arr1=arr1[len_arr1-1]
            else:
                arr1.append([])
                len_arr1 = len(arr1)
                arr1=arr1[len_arr1-1]
    arr1.append(o)

import json
print("nested_array == "+json.dumps(nested_array, indent=4, sort_keys=True, default=str))

## STEP3: Using Combined.pdf and Total nested array of outline create Combined.pdf with toc**

from PyPDF2 import PdfFileWriter, PdfFileReader
output = PdfFileWriter()
print("PYPDF2 PYTHON READING FILE:: "+combinedfile)
input1 = PdfFileReader(open(combinedfile, 'rb'))

total_pages = input1.getNumPages()
for pageno in range(total_pages):
    print(str(pageno+1)+"/"+str(total_pages)+" :: Adding pages to writer")
    output.addPage(input1.getPage(pageno-1))

total_bookmarks=toclen

j=0;
start_time = time.time()
# your code
def _write_bookmarks(bookmarks,j,parent=None):
    global total_bookmarks
    last_added = None
    for b in bookmarks:
        if isinstance(b, list):
            j=_write_bookmarks(b,j,last_added)
            continue
        last_added = output.addBookmark(b["/Title"], b["/Page"]-1,parent)
        elapsed_time = time.time() - start_time
        if j % 50 == 0:
            print(str(j)+"/"+str(total_bookmarks)+" :: J :: _write_bookmarks")
            print(str(time.strftime("%H:%M:%S", time.gmtime(elapsed_time)))+"  /  "+str(time.strftime("%H:%M:%S, %m/%d/%Y", time.localtime(start_time)))+" :: elapsed_time/start_time")
            #print(str(j)+" :: J :: _write_bookmarks")
        j=j+1

    return j


total=_write_bookmarks(nested_array,0)

# get filename from combinedfile.pdf
# os.path.splitext(combinedfile)[0]

#get (ext).pdf from combinedfile.pdf
# os.path.splitext(combinedfile)[1]

import os
outputfile = open(os.path.splitext(combinedfile)[0]+"_indexed"+os.path.splitext(combinedfile)[1], 'wb')
output.write(outputfile)
```

## AS BASH FILE

```bash
set -x -o verbose
##INPUT
## declare an array variable
#declare -a arr=("FILE1.pdf" "FILE2.pdf" "FILE3.pdf")
declare -a arr=("Adi_index.pdf" "Mad1_index.pdf" "Mad2_index.pdf" "Ant_index.pdf")

combinedfile="Combined.pdf"

# STEP1 COMBINE USING STAPLER
#stapler --verbose cat ${arr[@]} ${combinedfile}



# STEP2: Get the combined nested toc/outline python array

## now loop through the above array
array_str=""
for i in "${arr[@]}"
do
   array_str=${array_str}"\""$i"\", "
done

# allow for empty array
array_str=`echo ${array_str} | sed -e 's/,$//g' -e 's/""//g'`

cat << EOF > "Combine_pdfs_autogenerated.py"
import json
import fitz
import time
# STEP A: GET THE FLATTENED TOTAL OUTLINES
fileslist=[${array_str[@]}]
combinedfile="${combinedfile}"

print("fileslist:: "+str(fileslist))
print("combinedfile:: "+combinedfile)

# combining toc and also updating the bookmark page number
outlines=[]
total_pages=0
for i in range(len(fileslist)):
    print("mupdf READING FILE:: "+fileslist[i])
    doc = fitz.open(fileslist[i])  # open file
    toc = doc.getToC(False)
    new_toc=[]
    for line in toc:  # read TOC to update its page numbers
        line[2] = line[2] + total_pages  # add total page count to this page number
        new_toc.append(line)
    outlines = outlines + new_toc
    total_pages = total_pages + len(doc)

new_format=[]
for line in outlines:  # read toc 
    new_format.append({"/Page": line[2],"/Title": line[1],"/Type": "/Fit","level": line[0]})

file1 = open("combined_toc_dump_flatten.txt","a")
file1.write(json.dumps(new_format, indent=4, sort_keys=True, default=str))
file1.close() 

print(new_format)

# STEP B: CONVERT FLATTEN TOC FROM MUPDF TO NESTED FORMAR OF PYPDF2
toc = new_format.copy()

toclen = len(toc)

nested_array=[]
for i in range(toclen):
    o = toc[i]
    n=toc[i]["level"]
    #print("n=toc[i][\"level\"]:: i,n ::"+str(i)+","+str(n))
    index=""
    arr1 = None
    for j in range(0,n):
        #print("i,j ::::"+str(i)+","+str(j))
        if arr1 is None:
            arr1 = nested_array
        else:
            len_arr1 = len(arr1)
            if isinstance(arr1[len_arr1-1], list):
                arr1=arr1[len_arr1-1]
            else:
                arr1.append([])
                len_arr1 = len(arr1)
                arr1=arr1[len_arr1-1]
    arr1.append(o)

import json
print("nested_array == "+json.dumps(nested_array, indent=4, sort_keys=True, default=str))

## STEP3: Using Combined.pdf and Total nested array of outline create Combined.pdf with toc**

from PyPDF2 import PdfFileWriter, PdfFileReader
output = PdfFileWriter()
print("PYPDF2 PYTHON READING FILE:: "+combinedfile)
input1 = PdfFileReader(open(combinedfile, 'rb'))

total_pages = input1.getNumPages()
for pageno in range(total_pages):
    print(str(pageno+1)+"/"+str(total_pages)+" :: Adding pages to writer")
    output.addPage(input1.getPage(pageno-1))

total_bookmarks=toclen

j=0;
start_time = time.time()
# your code
def _write_bookmarks(bookmarks,j,parent=None):
    global total_bookmarks
    last_added = None
    for b in bookmarks:
        if isinstance(b, list):
            j=_write_bookmarks(b,j,last_added)
            continue
        last_added = output.addBookmark(b["/Title"], b["/Page"]-1,parent)
        elapsed_time = time.time() - start_time
        if j % 50 == 0:
            print(str(j)+"/"+str(total_bookmarks)+" :: J :: _write_bookmarks")
            print(str(time.strftime("%H:%M:%S", time.gmtime(elapsed_time)))+"  /  "+str(time.strftime("%H:%M:%S, %m/%d/%Y", time.localtime(start_time)))+" :: elapsed_time/start_time")
            #print(str(j)+" :: J :: _write_bookmarks")
        j=j+1

    return j


total=_write_bookmarks(nested_array,0)

# get filename from combinedfile.pdf
# os.path.splitext(combinedfile)[0]

#get (ext).pdf from combinedfile.pdf
# os.path.splitext(combinedfile)[1]

import os
outputfile = open(os.path.splitext(combinedfile)[0]+"_indexed"+os.path.splitext(combinedfile)[1], 'wb')
output.write(outputfile)
EOF

python Combine_pdfs_autogenerated.py

set +x +o verbose
```

Observation:

For a Combined.pdf size of 50,000 + pages and a toc of 15,000, it took 15+ min


# Adding boomarks using mupdf without PyPDF2

## STEP1: Combine the pdfs using stalpler

```bash
## STEP0: Combine the pdfs using stapler**
# stapler --verbose cat File1.pdf File2.pdf File3.pdf File4.pdf Combined.pdf
```

## STEP2: Club the toc of the files used for creating Combined.pdf

```python
import json
import fitz
import time
# STEP A: GET THE TOTAL OUTLINES
fileslist=["Adi_index.pdf", "Mad1_index.pdf", "Mad2_index.pdf", "Ant_index.pdf", ]

print("fileslist:: "+str(fileslist))


# combining toc and also updating the bookmark page number
outlines=[]
total_pages=0
for i in range(len(fileslist)):
    print("mupdf READING FILE:: "+fileslist[i])
    doc = fitz.open(fileslist[i])  # open file
    toc = doc.getToC(False)
    new_toc=[]
    for line in toc:  # read TOC to update its page numbers
        line[2] = line[2] + total_pages  # add total page count to this page number
        new_toc.append(line)
    outlines = outlines + new_toc
    total_pages = total_pages + len(doc)

file1 = open("combined_toc_dump_mupdf.txt","a")
file1.write(json.dumps(outlines, indent=4, sort_keys=True, default=str))
file1.close() 
```

## STEP3: ADD THE TOTAL OUTLINES TO THE Combined.pdf

```python
import fitz
combinedfile="Combined.pdf"
print("combinedfile:: "+combinedfile)
doc_total=fitz.open(combinedfile)
doc_total.setToC(outlines)  # get the outlines from the above code

# get filename from combinedfile.pdf
# os.path.splitext(combinedfile)[0]

#get (ext).pdf from combinedfile.pdf
# os.path.splitext(combinedfile)[1]

outputfile = open(os.path.splitext(combinedfile)[0]+"_indexed"+os.path.splitext(combinedfile)[1], 'wb')
doc_total.save(docfinal)
```

# Combining the code for mupdf toc



# Changes to be made in the source code of Mupdf setTOC

`/fitz/utils.py`

```python
def setToC(doc, toc, collapse=1):
    """Create new outline tree (table of contents, TOC).

    Args:
        toc: (list, tuple) each entry must contain level, title, page and
            optionally top margin on the page. None or '()' remove the TOC.
        collapse: (int) collapses entries beyond this level. Zero or None
            shows all entries unfolded.
    Returns:
        the number of inserted items, or the number of removed items respectively.
    """
    if doc.isClosed or doc.isEncrypted:
        raise ValueError("document closed or encrypted")
    if not doc.isPDF:
        raise ValueError("not a PDF")
    if not toc:  # remove all entries
        return len(doc._delToC())

    # validity checks --------------------------------------------------------
    if type(toc) not in (list, tuple):
        raise ValueError("'toc' must be list or tuple")
    toclen = len(toc)
    pageCount = doc.pageCount
    t0 = toc[0]
    if type(t0) not in (list, tuple):
        raise ValueError("items must be sequences of 3 or 4 items")
    if t0[0] != 1:
        raise ValueError("hierarchy level of item 0 must be 1")
    for i in list(range(toclen - 1)):
        t1 = toc[i]
        t2 = toc[i + 1]
        if not -1 <= t1[2] <= pageCount:
            raise ValueError("row %i: page number out of range" % i)
        if (type(t2) not in (list, tuple)) or len(t2) not in (3, 4):
            raise ValueError("bad row %i" % (i + 1))
        if (type(t2[0]) is not int) or t2[0] < 1:
            raise ValueError("bad hierarchy level in row %i" % (i + 1))
        if t2[0] > t1[0] + 1:
            raise ValueError("bad hierarchy level in row %i" % (i + 1))
    # no formal errors in toc --------------------------------------------------

    # --------------------------------------------------------------------------
    # make a list of xref numbers, which we can use for our TOC entries
    # --------------------------------------------------------------------------
    old_xrefs = doc._delToC()  # del old outlines, get their xref numbers
    old_xrefs = []  # TODO do not reuse them currently
    # prepare table of xrefs for new bookmarks
    xref = [0] + old_xrefs
    xref[0] = doc._getOLRootNumber()  # entry zero is outline root xref#
    if toclen > len(old_xrefs):  # too few old xrefs?
        for i in range((toclen - len(old_xrefs))):
            xref.append(doc._getNewXref())  # acquire new ones

    lvltab = {0: 0}  # to store last entry per hierarchy level

    # ------------------------------------------------------------------------------
    # contains new outline objects as strings - first one is the outline root
    # ------------------------------------------------------------------------------
    olitems = [{"count": 0, "first": -1, "last": -1, "xref": xref[0]}]
    # ------------------------------------------------------------------------------
    # build olitems as a list of PDF-like connnected dictionaries
    # ------------------------------------------------------------------------------
    for i in range(toclen):
        o = toc[i]
        lvl = o[0]  # level
        title = getPDFstr(o[1])  # title
        pno = min(doc.pageCount - 1, max(0, o[2] - 1))  # page number

######## FOR MY REQUIREMENT OF ONLY OUTLINE I DONT NEED THIS #######################
#####        page = doc[pno]  # load the page
#####        ictm = ~page.transformationMatrix  # get inverse transformation matrix
#####        top = Point(72, 36) * ictm  # default top location
#####        dest_dict = {"to": top, "kind": LINK_GOTO}  # fall back target
#####        if o[2] < 0:
#####            dest_dict["kind"] = LINK_NONE
#####        if len(o) > 3:  # some target is specified
#####            if type(o[3]) in (int, float):  # convert a number to a point
#####                dest_dict["to"] = Point(72, o[3]) * ictm
#####            else:  # if something else, make sure we have a dict
#####                dest_dict = o[3] if type(o[3]) is dict else dest_dict
#####                if "to" not in dest_dict:  # target point not in dict?
#####                    dest_dict["to"] = top  # put default in
#####                else:  # transform target to PDF coordinates
#####                    point = dest_dict["to"] * ictm
#####                    dest_dict["to"] = point
##################################################################################

        ### MODIFIED dest_dic
        dest_dict = {"to": Point(0, 0), "kind": LINK_GOTO}
        d = {}
        d["first"] = -1
        d["count"] = 0
        d["last"] = -1
        d["prev"] = -1
        d["next"] = -1
        ## MODIFIED page.xref
        #d["dest"] = getDestStr(page.xref, dest_dict)
        d["dest"] = getDestStr(doc._getPageObjNumber(pno)[0], dest_dict)
        d["top"] = dest_dict["to"]
        d["title"] = title
        d["parent"] = lvltab[lvl - 1]
        d["xref"] = xref[i + 1]
        lvltab[lvl] = i + 1
        parent = olitems[lvltab[lvl - 1]]  # the parent entry

        if collapse and lvl > collapse:  # suppress expansion
            parent["count"] -= 1  # make /Count negative
        else:
            parent["count"] += 1  # positive /Count

        if parent["first"] == -1:
            parent["first"] = i + 1
            parent["last"] = i + 1
        else:
            d["prev"] = parent["last"]
            prev = olitems[parent["last"]]
            prev["next"] = i + 1
            parent["last"] = i + 1
        olitems.append(d)
        obj={
        "i":i,
        "toclen": toclen
        }
        if i % 1000 == 0:
            print("setToC recursion == "+json.dumps(obj, indent=4, sort_keys=True, default=str))


    # ------------------------------------------------------------------------------
    # now create each outline item as a string and insert it in the PDF
    # ------------------------------------------------------------------------------
    for i, ol in enumerate(olitems):
        txt = "<<"
        if ol["count"] != 0:
            txt += "/Count %i" % ol["count"]
        try:
            txt += ol["dest"]
        except:
            pass
        try:
            if ol["first"] > -1:
                txt += "/First %i 0 R" % xref[ol["first"]]
        except:
            pass
        try:
            if ol["last"] > -1:
                txt += "/Last %i 0 R" % xref[ol["last"]]
        except:
            pass
        try:
            if ol["next"] > -1:
                txt += "/Next %i 0 R" % xref[ol["next"]]
        except:
            pass
        try:
            if ol["parent"] > -1:
                txt += "/Parent %i 0 R" % xref[ol["parent"]]
        except:
            pass
        try:
            if ol["prev"] > -1:
                txt += "/Prev %i 0 R" % xref[ol["prev"]]
        except:
            pass
        try:
            txt += "/Title" + ol["title"]
        except:
            pass
        if i == 0:  # special: this is the outline root
            txt += "/Type/Outlines"  # so add the /Type entry
        txt += ">>"

        obj={
        "i":i,
        "xref[i]": xref[i],
        "txt":txt
        }
        doc._updateObject(xref[i], txt)  # insert the PDF object

    doc.initData()
    return toclen
```