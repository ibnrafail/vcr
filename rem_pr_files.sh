#!/bin/bash

# Removing previously created data (from last run.sh execution)
rm -rf exp mfcc data/train/{spk2utt,cmvn.scp,feats.scp,split*} data/test/{spk2utt,cmvn.scp,feats.scp,split*} data/local/lang data/{lang,kws} data/local/tmp data/local/dict/lexiconp.txt kws_results
