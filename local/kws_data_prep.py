#!/usr/bin/python
import sys
import os
import time
if len(sys.argv) != 4:
    print("Usage: local/kws_data_prep.py <lang-dir> <data-dir> <kws-data-dir>")
    print("e.g.: local/kws_data_prep.py data/lang data/test data/kws")
    exit(1)

langdir = sys.argv[1]
datadir = sys.argv[2]
kwsdatadir = sys.argv[3]

print("1.Create keyword id for each keyword")
raw_keywords = open(kwsdatadir + "/raw_keywords.txt", "r")
keywords = open(kwsdatadir + "/keywords.txt", "w")

i = 1
line = raw_keywords.readline()
while line:
    s = "WSJ-%04d" % i
    keywords.write("WSJ-%04d" % i + " " + line)
    line = raw_keywords.readline()
    i += 1

raw_keywords.close()
keywords.close()
print("Keyword ids created.\n")

print("2. run compile_keywords_to_fsts.sh")
bashCommand = "sh /home/iskandar/Desktop/kaldi/kaldi-trunk/egs/digits_new/local/compile_keywords_to_fsts.sh " + langdir + " " + kwsdatadir
retval = os.system(bashCommand)
time.sleep(1)
print("Returned: " + str(retval) + "\n")


# Create utterance id for each utterance; Note that by "utterance" here I mean
# the keys that will appear in the lattice archive. You may have to modify here
print("3. Create utterance id for each utterance.")
wav_scp = open(datadir + "/wav.scp", "r")
utter_id = open(kwsdatadir + "/utter_id", "w")
i = 1
line = wav_scp.readline()
while line:
    ut, fname = line.split(" ")
    utter_id.write(ut + " " + str(i) + "\n")
    line = wav_scp.readline()
    i += 1
wav_scp.close()
utter_id.close()
print("Utterance ids created.\n")

# Map utterance to the names that will appear in the rttm file. You have
# to modify the commands below accoring to your rttm file. In the WSJ case
# since each file is an utterance, we assume that the actual file names will
# be the "names" in the rttm, so the utterance names map to themselves.
print("4. Map utterance to file names.")
wav_scp = open(datadir + "/wav.scp", "r")
utter_map = open(kwsdatadir + "/utter_map", "w")
i = 1
line = wav_scp.readline()
while line:
    ut, fname = line.split(" ")
    name = fname.split("/")
    finalname = name[len(name)-1].split(".")
    utter_map.write(ut + " " + finalname[0] + "\n")
    line = wav_scp.readline()
    i += 1
wav_scp.close()
utter_map.close()
print("Mapping finished.\n")