#!/bin/bash
. ./path.sh || exit 1
. ./cmd.sh || exit 1

nj=3

echo
echo "===== TRI4b TRAINING ====="
echo
steps/train_quick.sh --cmd "$train_cmd" 4200 40000 data/train data/lang exp/tri3b_ali exp/tri4b || exit 1;
echo
echo "===== TRI4b DECODING ====="
echo
utils/mkgraph.sh data/lang exp/tri4b exp/tri4b/graph || exit 1;
steps/decode_fmllr.sh --nj 1 --cmd "$decode_cmd" exp/tri4b/graph data/test exp/tri4b/decode || exit 1;
echo
echo "===== TRI4b ALIGNMENT =====" 
echo
# Train and test MMI, and boosted MMI, on tri4b (LDA+MLLT+SAT on
# all the data).  Use 30 jobs.
steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/tri4b exp/tri4b_ali || exit 1;
