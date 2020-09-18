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

**MODIFY SOURCE CODE OF STAPLER**

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
**MODIFY SOURCE CODE OF PyPDF2 python2**

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

**AFTER CHANGES THE OUTPUT WILL BE**
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

## Extract large pdfs TOC

### Use mupdf to get into the flatten format**
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


### Convert toc from flatten format to the format of PyPDF2 (i.e nested array)

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
```
