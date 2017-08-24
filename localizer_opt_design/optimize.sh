#!/bin/bash

# command line arguments
N=$1 #the number of iterations
NT=$2 # number of time points (in seconds)
TR=$3
n_reps=$4 # number of blocks for each type
len_block=$5 # the length of block for each type (in seconds)
prefix=`echo reps-${n_reps}_len-${len_block}`

# more fine-grained timing control when generating stimulus timing
time_steps=0.1 
NT_ts=`awk "BEGIN {print $NT/$time_steps}"`
len_block_ts=`awk "BEGIN {print $len_block/$time_steps}"`

mkdir $prefix
cd $prefix
echo "iteration stimulus_eff contrast_eff seed" > ${prefix}.results.txt

for i in $(seq 1 $N)
do

#portable method of getting a random number
seed=`cat /dev/random|head -c 256|cksum |awk '{print $1}'`

# use RSFgen to simulate a design based on inputs
# 6 conditions:
# right hand, left hand, right foot, left foot, tongue, null
RSFgen \
-nt $NT_ts \
-num_stimts 6 \
-nreps 1 $n_reps -nblock 1 $len_block_ts \
-nreps 2 $n_reps -nblock 2 $len_block_ts \
-nreps 3 $n_reps -nblock 3 $len_block_ts \
-nreps 4 $n_reps -nblock 4 $len_block_ts \
-nreps 5 $n_reps -nblock 5 $len_block_ts \
-nreps 6 $n_reps -nblock 6 $len_block_ts \
-seed $seed \
-prefix ${prefix}.${i}.

make_stim_times.py \
-files ${prefix}.${i}.*.1D \
-prefix ${prefix}.stim.${i} \
-nt $NT_ts \
-tr $time_steps \
-nruns 1

3dDeconvolve \
-nodata `awk "BEGIN {print $NT/$TR}"` $TR \
-polort 'A' \
-num_stimts 6 \
-stim_times 1 ${prefix}.stim.${i}.01.1D 'BLOCK('$len_block')' \
-stim_label 1 'RH' \
-stim_times 2 ${prefix}.stim.${i}.02.1D 'BLOCK('$len_block')' \
-stim_label 2 'LH' \
-stim_times 3 ${prefix}.stim.${i}.03.1D 'BLOCK('$len_block')' \
-stim_label 3 'RF' \
-stim_times 4 ${prefix}.stim.${i}.04.1D 'BLOCK('$len_block')' \
-stim_label 4 'LF' \
-stim_times 5 ${prefix}.stim.${i}.05.1D 'BLOCK('$len_block')' \
-stim_label 5 'T' \
-stim_times 6 ${prefix}.stim.${i}.06.1D 'BLOCK('$len_block')' \
-stim_label 6 'Null' \
-gltsym "SYM: 0.5*RH 0.5*LH -0.5*RF -0.5*LF" \
-gltsym "SYM: 0.5*RH 0.5*LH -T" \
-gltsym "SYM: 0.5*RF 0.5*LF -T" > ${prefix}.efficiency.${i}.txt

eff=`../efficiency_parser.py ${prefix}.efficiency.${i}.txt`

echo "$i $eff $seed" >> ${prefix}.results.txt

done

cd ..
