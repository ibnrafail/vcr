#!/bin/bash

duration=`feat-to-len scp:data/test/feats.scp  ark,t:- | awk '{x+=$2} END{print x/100;}'`
# TODO use kws_setup.sh script with ucf.xml, rttm, kwslist.xml files
local/generate_example_kws.sh data/test data/kws
local/kws_data_prep.sh data/lang data/test data/kws

steps/make_index.sh --cmd "$decode_cmd" --acwt 0.1 data/kws data/lang exp/mono/decode exp/mono/decode/kws
steps/search_index.sh --cmd "$decode_cmd" data/kws exp/mono/decode/kws

# If you want to provide the start time for each utterance, you can use the --segments
# option. In WSJ each file is an utterance, so we don't have to set the start time.
cat exp/mono/decode/kws/result.* | utils/write_kwslist.pl --flen=0.01 --duration=$duration --normalize=true --map-utter=data/kws/utter_map - exp/mono/decode/kws/kwslist.xml
