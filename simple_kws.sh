#!/bin/bash
. ./path.sh || exit 1
. ./cmd.sh || exit 1

# delete previosly created files
rm -rf data/kws exp/mono/decode/kws

duration=`feat-to-len scp:data/test/feats.scp  ark,t:- | awk '{x+=$2} END{print x/100;}'`
# TODO use kws_setup.sh script with ucf.xml, rttm, kwslist.xml files
echo
echo "=== GENERATE EXAMPLE KWS ==="
echo
local/generate_example_kws.sh data/test data/kws
echo
echo "=== KWS DATA PREPARATION ==="
echo
#local/kws_data_prep.sh data/lang data/test data/kws
./local/kws_data_prep.py data/lang data/test data/kws
echo
echo "=== MAKE INDEX ==="
echo
steps/make_index.sh --cmd "$decode_cmd" --acwt 0.1 data/kws data/lang exp/mono/decode exp/mono/decode/kws
echo
echo "=== SEARCH INDEX ==="
echo
steps/search_index.sh --cmd "$decode_cmd" data/kws exp/mono/decode/kws
echo
echo "=== GENERATE KWSLIST ==="
echo
# If you want to provide the start time for each utterance, you can use the --segments
# option. In WSJ each file is an utterance, so we don't have to set the start time.
cat exp/mono/decode/kws/result.* | utils/write_kwslist.pl --flen=0.01 --kwlist-filename "kwlist.xml" --language "English" --system-id "digits" --duration=$duration --normalize=true --map-utter=data/kws/utter_map - exp/mono/decode/kws/kwslist.xml

echo
echo "=== GENERATE ECF FILE==="
echo
$KALDI_ROOT/egs/digits_new/gen_ecf.py $KALDI_ROOT/egs/digits_new/digits_audio/test/mark $KALDI_ROOT/egs/digits_new/data/kws
echo
echo "=== GENERATE KWLIST ==="
echo
$KALDI_ROOT/egs/digits_new/gen_kwlist.py $KALDI_ROOT/egs/digits_new/data/kws/keywords.txt $KALDI_ROOT/egs/digits_new/data/kws
echo
echo "=== GENERATE RTTM ==="
echo
$KALDI_ROOT/egs/digits_new/local/ali_to_rttm.sh $KALDI_ROOT/egs/digits_new/data $KALDI_ROOT/egs/digits_new/data/lang $KALDI_ROOT/egs/digits_new/exp/mono

$KALDI_ROOT/egs/digits_new/local/rttm_fix_filenames.py $KALDI_ROOT/egs/digits_new/exp/mono/rttm

KWSEval -e data/kws/ecf.xml -r $KALDI_ROOT/egs/digits_new/exp/mono/rttm -s $KALDI_ROOT/egs/digits_new/exp/mono/decode/kws/kwslist.xml -t $KALDI_ROOT/egs/digits_new/data/kws/kwlist.xml -f $KALDI_ROOT/egs/digits_new/kws_results/ -o -b -d

