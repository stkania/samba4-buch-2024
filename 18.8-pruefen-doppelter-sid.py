#!/usr/bin/python
# A quick and dirty python script that checks for duplicate SIDs using slapcat.

import os
 data = os.popen("slapcat | grep sambaSID", 'r')
line = []

def anydup(thelist):
        dups = list(set([x for x in thelist if thelist.count(x) > 1]))
        for i in dups:
                print "Duplicate id: ", i

for each_line in data:
        line.append(each_line.strip())

anydup(line)

