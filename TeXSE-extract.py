#!/usr/bin/python

import fileinput
incode=False
n=0
for line in fileinput.input():
    if not incode:
        if line.startswith('<pre><code>'):
            incode=True
            n+=1
            f=open('{}.tex'.format(n), 'w')
            line = line[11:]
    if incode:
        if line.startswith('</code></pre>'):
            incode=False
            f.close()
        else:
            print(line, end='', file=f)
