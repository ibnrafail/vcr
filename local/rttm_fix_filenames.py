#!/usr/bin/python
import os
import sys

if len(sys.argv) != 2:
    print("Usage: local/rttm_fix_filenames.py <rttm-file>")
    exit(1)

rttm = sys.argv[1]

print("Fix filenames in rttm file.")
rttmfile = open(rttm, "r")
i = 1

rttmlines = rttmfile.readlines()
rttmlinesfin = []
for i in rttmlines:
     i = i.replace("mark_", "")
     rttmlinesfin.append(i)

rttmfile.close()

rttmfile = open(rttm, "w")
for i in rttmlinesfin:
    rttmfile.write(i)
rttmfile.close()