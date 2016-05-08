#!/bin/bash
. ./path.sh || exit 1
. ./cmd.sh || exit 1

nj=3

echo
echo "===== TRI2b TRAINING ====="
echo
steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 2500 15000 data/train data/lang exp/tri1_ali exp/tri2b || exit 1;

echo
echo "===== TRI2b DECODING ====="
echo
utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph || exit 1;
steps/decode.sh --nj 1 --cmd "$decode_cmd" exp/tri2b/graph data/test exp/tri2b/decode || exit 1;

echo
echo "===== TRI2b ALIGNMENT =====" 
echo
# Align tri2b system.
steps/align_si.sh  --nj $nj --cmd "$train_cmd" --use-graphs true data/train data/lang exp/tri2b exp/tri2b_ali  || exit 1;
