#!/usr/bin/env python
import sys
from xml.etree.ElementTree import Element, SubElement, Comment, tostring
from pretty_xml import prettify
from os import listdir
from os.path import isfile, join, exists, relpath


def create_kwlist(ecf_filename, language, encoding, compareNormalize, version):
    kwlist = Element("kwlist")
    kwlist.set("ecf_filename", ecf_filename)
    kwlist.set("language", language)
    kwlist.set("encoding", encoding)
    kwlist.set("compareNormalize", compareNormalize)
    kwlist.set("version", version)
    return kwlist


def create_kw(kwlist, kwid, kwtext_):
    kw = SubElement(kwlist, "kw")
    kw.set("kwid", kwid)
    kwtext = SubElement(kw, "kwtext")
    kwtext.text = kwtext_


def get_ids_and_keywords(keywords_file):
    f = open(keywords_file, "r")
    list_of_lines = f.readlines()
    return list_of_lines


if len(sys.argv) != 3:
    print("Usage: " + relpath(sys.argv[0]) + " keywords_file kwlist_dir")
    exit(1)

keywords_file = sys.argv[1]
kwlist_dir = sys.argv[2]

print("kwlist file generation")
if exists(keywords_file) is False:
    print("Error:" + audio_dir + " no such file or directory.")
    exit(1)
if exists(kwlist_dir) is False:
    print("Error:" + ecf_dir + " no such file or directory.")
    exit(1)
print("The paths exist.")

print("Doing job...")
keywords = get_ids_and_keywords(keywords_file)
kwlist = create_kwlist("ecf.xml", "English", "UTF-8", "lowercase", "1.0")
for i in keywords:
    id, keyword = i.split(" ")
    create_kw(kwlist, id, keyword[:-1])

output_kwlist_file = open(kwlist_dir + "/kwlist.xml", "w")
output_kwlist_file.write(prettify(kwlist))
output_kwlist_file.close()
print("Job done!")