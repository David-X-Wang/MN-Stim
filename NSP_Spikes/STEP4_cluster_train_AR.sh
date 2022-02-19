#!/bin/bash


## ACTION ITEM::::: you likely have your own python environment - activate it here! if not, comment out the following line to use root env

module load combinato/20200804

# declare the list of session directories


declare -a arr=("/project/TIBIR/Lega_lab/s427026/UT255/sorted/session_0/RawDir/combinato_files")	


## now loop through the above array

## OPTIONAL: 

mkdir /project/TIBIR/Lega_lab/shared/lega_ansir/Pranish_Micro_AR/test/combinato_clustering/$(date '+%d-%b-%Y') # make a directory to store the job file in
cd /project/TIBIR/Lega_lab/shared/lega_ansir/Pranish_Micro_AR/test/combinato_clustering/$(date '+%d-%b-%Y')
touch do_manual_neg.txt # This makes a job file if you want to use css-overview
#touch do_manual_pos.txt

for file in "${arr[@]}"; do
	cd $file


	# Loop through all the NS6 Extractions
	for chan in *.hdf5; do  
		# run the extraction. Might take a little while 
		css-extract --files "${chan}" --h5
	done
	
	# css-find-concurrent --concurrent-file concurrent_times.h5
	css-mask-artifacts

    ls */*.h5 > do_sort.txt
    css-prepare-sorting --neg --jobs do_sort.txt
    css-cluster --jobs sort_neg_s42.txt
    css-combine --jobs sort_neg_s42.txt

	
done
