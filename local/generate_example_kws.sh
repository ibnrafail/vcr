#!/bin/bash

# Copyright 2012  Johns Hopkins University (Author: Guoguo Chen)
# Apache 2.0.


if [ $# -ne 2 ]; then
   echo "Usage: local/generate_example_kws.sh <data-dir> <kws-data-dir>"
   echo " e.g.: local/generate_example_kws.sh data/test_eval92/ <data/kws>"
   exit 1;
fi

datadir=$1;
kwsdatadir=$2;
text=$datadir/text;

mkdir -p $kwsdatadir;

# Generate keywords; we generate 20 unigram keywords with at least 20 counts,
# 20 bigram keywords with at least 10 counts and 10 trigram keywords with at
# least 5 counts.
echo "one" >> $kwsdatadir/raw_keywords.txt
echo "four" >> $kwsdatadir/raw_keywords.txt
echo "six" >> $kwsdatadir/raw_keywords.txt

echo "Keywords generation succeeded"
