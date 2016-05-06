#!/bin/bash

langdir=$1;
kwsdatadir=$2;

# Map the keywords to integers; note that we remove the keywords that
# are not in our $langdir/words.txt, as we won't find them anyway...
cat $kwsdatadir/keywords.txt | ../utils/sym2int.pl --map-oov 0 -f 2- $langdir/words.txt | grep -v " 0 " | grep -v " 0$" > $kwsdatadir/keywords.int

# Compile keywords into FSTs
../../../src/kwsbin/transcripts-to-fsts ark:$kwsdatadir/keywords.int ark:$kwsdatadir/keywords.fsts
