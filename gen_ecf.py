#!/usr/bin/python
import sys
from xml.etree.ElementTree import Element, SubElement, Comment, tostring
from pretty_xml import prettify
from os import listdir
from os.path import isfile, join, exists, relpath
from pydub import AudioSegment


# filename, duration_seconds, channels
# bnews Broadcast News
# conmtg Conferences & Meetings
# cts Conversational Telephone Speech
# splitcts

def create_ecf(source_signal_duration, language, version):
    ecf = Element('ecf')
    ecf.set("source_signal_duration", source_signal_duration)
    ecf.set("language", language)
    ecf.set("version", version)
    return ecf


def create_excerpt(ecf, audio_filename, channels, tbeg, duration, source_type):
    excerpt = SubElement(ecf, 'excerpt')
    excerpt.set("audio_filename", audio_filename)
    excerpt.set("channel", channels)
    excerpt.set("tbeg", tbeg)
    excerpt.set("dur", duration)
    excerpt.set("source_type", source_type)
    return excerpt

if len(sys.argv) != 3:
    print("Usage: " + relpath(sys.argv[0]) + " audio_dir ecf_dir")
    exit(1)

audio_dir = sys.argv[1]
ecf_dir = sys.argv[2]

print("ecf file generation")
if exists(audio_dir) is False:
    print("Error:" + audio_dir + " no such file or directory.")
    exit(1)
if exists(ecf_dir) is False:
    print("Error:" + ecf_dir + " no such file or directory.")
    exit(1)
print("The paths exist.")
ecf = create_ecf("0.0", "English", "1.0")

total_duration = 0.0

files = [f for f in listdir(audio_dir) if isfile(join(audio_dir, f))]
print("Doing job...")
for f in files:
    if f.endswith(".wav"):
        audio = AudioSegment.from_wav(audio_dir + "/" + f)
        duration = audio.duration_seconds
        #s = ""
        #s = "%.2f" % duration
        #duration = float(s)
        total_duration += duration
        channels = audio.channels
        create_excerpt(ecf, audio_dir + "/" + f, str(channels), "0.0", str(duration), "splitcts")

ecf.set("source_signal_duration", str(total_duration))

output_ecf_file = open(ecf_dir + "/ecf.xml", "w")
output_ecf_file.write(prettify(ecf))
output_ecf_file.close()
print("Job done!")
