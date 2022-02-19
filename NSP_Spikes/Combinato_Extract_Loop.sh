#!/bin/bash

declare -a arr='("/project/TIBIR/Lega_lab/shared/lega_ansir/Pranish_Micro_AR/UT178/10_31_19_AR_Micro/raw_spike_dir/clean_20200717")'


for file in "${arr[@]}"; do
	cd $file
	for chan in NS6_0[0-1][0-9]*.mat; do
		css-extract --matfile ${chan%%.*}.mat
	done

	css-mask-artifacts

done
