#!/bin/bash
. ./path.sh || exit 1
. ./cmd.sh || exit 1

nj=3

echo
echo "===== TRI1 ALIGNMENT =====" 
echo
steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

echo
echo "===== TRI2 TRAINING ====="
echo
# Train tri2, which is deltas + delta-deltas
steps/train_deltas.sh --cmd "$train_cmd" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2 || exit 1;

echo
echo "===== TRI2 DECODING ====="
echo
utils/mkgraph.sh data/lang exp/tri2 exp/tri2/graph || exit 1;
steps/decode.sh --nj 1 --cmd "$decode_cmd" exp/tri2/graph data/test exp/tri2/decode || exit 1;
