# Stapler to combine large pdfs

Stapler uses python2

**Command*
# stapler --verbose cat File1.pdf File2.pdf File3.pdf File4.pdf ALL.pdf

We want to club pdfs of each size 15000+ pages. So we want to see some indication while the pdfs are getting clubbed
So use `--verbose`

But `--verbose is not just sufficient` we want to see more indication whats happening. So do the following changes in the following files

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


