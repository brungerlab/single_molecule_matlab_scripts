# single_molecule_matlab_scripts #
single molecule matlab scripts of the Brunger lab

## /fusion_detector ##
matlab script to detect fusion events in time trace files

`Fusion_Detector_2_0_7_JL_atb_2.m`
This script imports traces from putative fusions events and filters these events by detecting peaks and analyzing the surrounding areas. The traces for the remaining putative fusion events are plotted one at a time and the user confirms or rejects each hit. The final hits are stored in a variable called "confirmedHits." If you have two channels, channel two hits are stored in confirmedHits2 Functions GUI2.m, textBox1.m, textBox2.m, and getkey.m are required for fusionDetector.

## /HMMbatchscript ##
matlab scripts to perform HMM analysis on single molecule trace files. 

`HMM_single_file_atb.m`
Single file version.

`HMM_batch_atb.m`
Batch version.


## /smCamera_conversion/smm_conversion ##

matlab script file to convert smCamera .smm trajectory files to .tif format.
`smm2tif_M_atb.m` 

Edit the name of the directory that contains the .smm files:
`path = <enter pathname here>;`
	
and then run in matlab. 
For each .smm file, a .tif file is created within the same directory.


## /smCamera_conversion/smt_conversion ##
matlab script file to convert smCamera .smt trace files (containing traces for each detected spot) to text format.

`ssmt2txtFiles_atb.m` 
Edit the name of the directory that contains the .smt files:
`path = '/<enter pathname here>';`

and then run in matlab. 
For each .smt file a subdirectory is created that contains the text files for each of the traces.

Alternative version that does not use double __ in resulting file names.
`ssmt2txtFiles_atb2.m` 
Edit the name of the directory that contains the .smt files:
`path = '/<enter pathname here>';`
	
and then run in matlab. 
For each .smt file a subdirectory is created that contains text files for each of the traces.
