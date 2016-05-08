#!/bin/bash
. ./path.sh || exit 1
. ./cmd.sh || exit 1

nj=3

echo
echo "===== TRI3b TRAINING ====="
echo
# From 2b system, train 3b which is LDA + MLLT + SAT.
steps/train_sat.sh --cmd "$train_cmd" 2500 15000 data/train data/lang exp/tri2b_ali exp/tri3b || exit 1;
echo
echo "===== TRI3b DECODING ====="
echo
utils/mkgraph.sh data/lang exp/tri3b exp/tri3b/graph || exit 1;
steps/decode_fmllr.sh --nj 1 --cmd "$decode_cmd" exp/tri3b/graph data/test exp/tri3b/decode || exit 1;

echo
echo "===== TRI3b ALIGNMENT =====" 
echo
# From 3b system, align all data.
steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri3b exp/tri3b_ali || exit 1;
