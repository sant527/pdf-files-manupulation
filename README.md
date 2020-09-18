# Stapler to combine large pdfs

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

