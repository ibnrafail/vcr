source ../../tools/env.sh
# Defining Kaldi root directory
export KALDI_ROOT=`pwd`/../..

# Setting paths to useful tools
export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/src/kwsbin/:$KALDI_ROOT/tools/F4DE/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin/:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin/:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin/:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin/:$KALDI_ROOT/src/latbin/:$PWD:$PATH

# Defining audio data directory (modify it for your installation directory!)
export DATA_ROOT="/home/iskandar/Desktop/kaldi-trunk/egs/digits/digits_audio"

# Variable that stores path to MITLM library
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)/tools/mitlm-svn/lib

# Variable needed for proper data sorting
export LC_ALL=C
