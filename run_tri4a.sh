#!/bin/bash
. ./path.sh || exit 1
. ./cmd.sh || exit 1

nj=3

echo
echo "===== TRI4a TRAINING ====="
echo
# From 3b system, train another SAT system (tri4a).
steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 data/train data/lang exp/tri3b_ali exp/tri4a || exit 1;
echo
echo "===== TRI4a DECODING ====="
echo
utils/mkgraph.sh data/lang exp/tri4a exp/tri4a/graph || exit 1;
steps/decode_fmllr.sh --nj 1 --cmd "$decode_cmd" exp/tri4a/graph data/test exp/tri4a/decode || exit 1;
