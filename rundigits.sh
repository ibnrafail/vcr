#!/bin/bash

. ./path.sh || exit 1
. ./cmd.sh || exit 1

nj=3       # number of parallel jobs - 1 is perfect for such a small data set
lm_order=1 # language model order (n-gram quantity) - 1 is enough for digits grammar

# Safety mechanism (possible running this script with modified arguments)
. utils/parse_options.sh || exit 1
[[ $# -ge 1 ]] && { echo "Wrong arguments!"; exit 1; } 

. rem_pr_files.sh || exit 1;

echo
echo "=== ACOUSTIC DATA PREPARATION ==="
echo
# spk2gender  [<speaker-id> <gender>]
# wav.scp     [<uterranceID> <full_path_to_audio_file>]
# text	      [<uterranceID> <text_transcription>]
# utt2spk     [<uterranceID> <speakerID>]
# corpus.txt  [<text_transcription>]

# _data_prep.sh

# Making spk2utt files
utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt

echo
echo "=== DICTIONARY PREPARATION ==="
echo
# extra_questions.txt   [Needs to be described]
# lexicon.txt           [<word> <phone 1> <phone 2> ...]		
# nonsilence_phones.txt	[<phone>]
# silence_phones.txt    [<phone>]
# optional_silence.txt  [<phone>]

# _prepare_dict.sh || exit 1;
# _format_data.sh || exit 1;



echo
echo "=== FEATURES EXTRACTION ==="
echo
# Making feats.scp files
mfccdir=mfcc
steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir
steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/test exp/make_mfcc/test $mfccdir

# Making cmvn.scp files
steps/compute_cmvn_stats.sh data/train exp/make_mfcc/train $mfccdir
steps/compute_cmvn_stats.sh data/test exp/make_mfcc/test $mfccdir

# echo
# echo "=== DATA DIR VALIDATION ==="
# echo
# utils/validate_data_dir.sh data/train || exit 1; # script for checking prepared data - here: for data/train directory

echo
echo "=== FIX DATA DIR ==="
echo
utils/fix_data_dir.sh data/train || exit 1; # tool for data proper sorting if needed - here: for data/train directory

echo
echo "=== LANGUAGE DATA PREPARATION ==="
echo
utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang || exit 1;

echo
echo "=== LANGUAGE MODEL CREATION ==="
echo "== 1. MAKING lm.arpa =="
echo

loc=`which ngram-count`;
if [ -z $loc ]; then
 	if uname -a | grep 64 >/dev/null; then
		sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64 
	else
    		sdir=$KALDI_ROOT/tools/srilm/bin/i686
  	fi
  	if [ -f $sdir/ngram-count ]; then
    		echo "Using SRILM language modelling tool from $sdir"
    		export PATH=$PATH:$sdir
  	else
    		echo "SRILM toolkit is probably not installed.
		      Instructions: tools/install_srilm.sh"
    		exit 1
  	fi
fi

local=data/local
mkdir $local/tmp
ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa

echo
echo "== 2. MAKING G.fst =="
echo

lang=data/lang
cat $local/tmp/lm.arpa | ../../src/lmbin/arpa2fst - | fstprint | utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$lang/words.txt --osymbols=$lang/words.txt --keep_isymbols=false --keep_osymbols=false | fstrmepsilon | fstarcsort --sort_type=ilabel > $lang/G.fst

echo
echo "===== MONO TRAINING ====="
echo

steps/train_mono.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono  || exit 1;

echo
echo "===== MONO DECODING ====="
echo

utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph || exit 1
steps/decode.sh --config conf/decode.config --nj 1 --cmd "$decode_cmd" exp/mono/graph data/test exp/mono/decode

echo
echo "===== MONO ALIGNMENT =====" 
echo

steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali || exit 1

echo
echo "===== TRI1 (first triphone pass) TRAINING ====="
echo

steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 data/train data/lang exp/mono_ali exp/tri1 || exit 1

echo
echo "===== TRI1 (first triphone pass) DECODING ====="
echo

utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
steps/decode.sh --config conf/decode.config --nj 1 --cmd "$decode_cmd" exp/tri1/graph data/test exp/tri1/decode

echo
echo "===== WORD-ALIGNED LATTICES ====="
echo
# demonstrate how to get lattices that are "word-aligned" (arcs coincide with
# words, with boundaries in the right place).
sil_label=`grep '!SIL' data/lang/words.txt | awk '{print $2}'`
steps/word_align_lattices.sh --cmd "$train_cmd" --silence-label $sil_label data/lang exp/tri1/decode exp/tri1/decode_aligned || exit 1;

#echo
#echo "===== TRI1 ALIGNMENT =====" 
#echo
#steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

#echo
#echo "===== TRI2 TRAINING ====="
#echo
# Train tri2, which is deltas + delta-deltas
#steps/train_deltas.sh --cmd "$train_cmd" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2 || exit 1;

#echo
#echo "===== TRI2 DECODING ====="
#echo
#utils/mkgraph.sh data/lang exp/tri2a exp/tri2/graph || exit 1;
#steps/decode.sh --nj 1 --cmd "$decode_cmd" exp/tri2/graph data/test exp/tri2/decode || exit 1;

#echo
#echo "===== TRI2b TRAINING ====="
#echo
#steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2b || exit 1;

#echo
#echo "===== TRI2b DECODING ====="
#echo
#utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph || exit 1;
#steps/decode.sh --nj 1 --cmd "$decode_cmd" exp/tri2b/graph data/test exp/tri2b/decode || exit 1;

#echo
#echo "===== TRI2b ALIGNMENT =====" 
#echo
# Align tri2b system.
#steps/align_si.sh  --nj $nj --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali  || exit 1;

#echo
#echo "===== TRI3b TRAINING ====="
#echo
# From 2b system, train 3b which is LDA + MLLT + SAT.
#steps/train_sat.sh --cmd "$train_cmd" 2500 15000 data/train data/lang exp/tri2b_ali exp/tri3b || exit 1;
#echo
#echo "===== TRI3b DECODING ====="
#echo
#utils/mkgraph.sh data/lang exp/tri3b exp/tri3b/graph || exit 1;
#steps/decode_fmllr.sh --nj 1 --cmd "$decode_cmd" exp/tri3b/graph data/test exp/tri3b/decode || exit 1;

#echo
#echo "===== TRI3b ALIGNMENT =====" 
#echo
# From 3b system, align all data.
#steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri3b exp/tri3b_ali || exit 1;

#echo
#echo "===== TRI4a TRAINING ====="
#echo
# From 3b system, train another SAT system (tri4a).
#steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 data/train data/lang exp/tri3b_ali exp/tri4a || exit 1;
#echo
#echo "===== TRI4a DECODING ====="
#echo
#utils/mkgraph.sh data/lang exp/tri4a exp/tri4a/graph || exit 1;
#steps/decode_fmllr.sh --nj 1 --cmd "$decode_cmd" exp/tri4a/graph data/test exp/tri4a/decode || exit 1;

#echo
#echo "===== TRI4b TRAINING ====="
#echo
#steps/train_quick.sh --cmd "$train_cmd" 4200 40000 data/train data/lang exp/tri3b_ali exp/tri4b || exit 1;
#echo
#echo "===== TRI4b DECODING ====="
#echo
#utils/mkgraph.sh data/lang exp/tri4b exp/tri4b/graph || exit 1;
#steps/decode_fmllr.sh --nj 1 --cmd "$decode_cmd" exp/tri4b/graph data/test exp/tri4b/decode || exit 1;
#echo
#echo "===== TRI4b ALIGNMENT =====" 
#echo
# Train and test MMI, and boosted MMI, on tri4b (LDA+MLLT+SAT on
# all the data).  Use 30 jobs.
#steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri4b exp/tri4b_ali || exit 1;

