#!/bin/bash
. ./path.sh || exit 1
. ./cmd.sh || exit 1

nj=3

# This script is invoked from ../run.sh
# It contains some SGMM-related scripts that I am breaking out of the main run.sh for clarity.

# Note: you might want to try to give the option --spk-dep-weights=false to train_sgmm2.sh;
# this takes out the "symmetric SGMM" part which is not always helpful.

# SGMM system on si84 data [sgmm5a].  Note: the system we aligned from used the si284 data for
# training, but this shouldn't have much effect.


steps/train_ubm.sh --cmd "$train_cmd" 400 data/train data/lang exp/tri4b_ali exp/ubm5a || exit 1;

steps/train_sgmm2.sh --cmd "$train_cmd" 7000 9000 data/train data/lang exp/tri4b_ali exp/ubm5a/final.ubm exp/sgmm2_5a || exit 1;

utils/mkgraph.sh data/lang_test_tgpr exp/sgmm2_5a exp/sgmm2_5a/graph_tgpr
steps/decode_sgmm2.sh --nj 1 --cmd "$decode_cmd" --transform-dir exp/tri4b/decode exp/sgmm2_5a/graph data/test exp/sgmm2_5a/decode

steps/align_sgmm2.sh --nj $nj --cmd "$train_cmd" --transform-dir exp/tri4b --use-graphs true --use-gselect true data/train data/lang exp/sgmm2_5a exp/sgmm2_5a_ali || exit 1;
steps/make_denlats_sgmm2.sh --nj $nj --sub-split 30 --cmd "$decode_cmd" --transform-dir exp/tri4b_ali data/train data/lang exp/sgmm2_5a_ali exp/sgmm2_5a_denlats

steps/train_mmi_sgmm2.sh --cmd "$decode_cmd" --transform-dir exp/tri4b_ali --boost 0.1 data/train data/lang exp/sgmm2_5a_ali exp/sgmm2_5a_denlats exp/sgmm2_5a_mmi_b0.1

for iter in 1 2 3 4; do
	steps/decode_sgmm2_rescore.sh --cmd "$decode_cmd" --iter $iter --transform-dir exp/tri4b/decode data/lang data/test exp/sgmm2_5a/decode exp/sgmm2_5a_mmi_b0.1/decode_it$iter &
done

steps/train_mmi_sgmm2.sh --cmd "$decode_cmd" --transform-dir exp/tri4b_ali --boost 0.1 --update-opts "--cov-min-value=0.9" data/train data/lang exp/sgmm2_5a_ali exp/sgmm2_5a_denlats exp/sgmm2_5a_mmi_b0.1_m0.9

for iter in 1 2 3 4; do
	steps/decode_sgmm2_rescore.sh --cmd "$decode_cmd" --iter $iter --transform-dir exp/tri4b/decode data/lang data/test exp/sgmm2_5a/decode exp/sgmm2_5a_mmi_b0.1_m0.9/decode_it$iter &
done

# Examples of combining some of the best decodings: SGMM+MMI with
# MMI+fMMI on a conventional system.
 
#local/score_combine.sh data/test_eval92 \
#   data/lang_test_bd_tgpr \
#   exp/tri4b_fmmi_a/decode_tgpr_eval92_it8 \
#   exp/sgmm2_5b_mmi_b0.1/decode_bd_tgpr_eval92_it3 \
#   exp/combine_tri4b_fmmi_a_sgmm2_5b_mmi_b0.1/decode_bd_tgpr_eval92_it8_3


# %WER 4.43 [ 250 / 5643, 41 ins, 12 del, 197 sub ] exp/tri4b_fmmi_a/decode_tgpr_eval92_it8/wer_11
# %WER 3.85 [ 217 / 5643, 35 ins, 11 del, 171 sub ] exp/sgmm2_5b_mmi_b0.1/decode_bd_tgpr_eval92_it3/wer_10
# combined to:
# %WER 3.76 [ 212 / 5643, 32 ins, 12 del, 168 sub ] exp/combine_tri4b_fmmi_a_sgmm2_5b_mmi_b0.1/decode_bd_tgpr_eval92_it8_3/wer_12

# Checking MBR decode of baseline:
#cp -r -T exp/sgmm2_5b_mmi_b0.1/decode_bd_tgpr_eval92_it3{,.mbr}
#local/score_mbr.sh data/test_eval92 data/lang_test_bd_tgpr exp/sgmm2_5b_mmi_b0.1/decode_bd_tgpr_eval92_it3.mbr
# MBR decoding did not seem to help (baseline was 3.85).  I think this is normal at such low WERs.
#%WER 3.86 [ 218 / 5643, 35 ins, 11 del, 172 sub ] exp/sgmm2_5b_mmi_b0.1/decode_bd_tgpr_eval92_it3.mbr/wer_10
