# single_molecule_matlab_scripts #
Single molecule scripts of the Brunger lab. 

**Note:some of the scripts require these MATLAB Add-Ons:**

Statistics and Machine Learning Toolbox
Image Processing Toolbox
Signal Processing Toolbox

## /fusion_detector ##
matlab script to detect fusion events in time trace files

`Fusion_Detector_2_0_8_JL.m`
This script imports traces from putative fusions events and filters these events by detecting peaks and analyzing the surrounding areas. The traces for the remaining putative fusion events are plotted one at a time and the user confirms or rejects each hit. The final hits are stored in a variable called "confirmedHits." If you have two channels, channel two hits are stored in confirmedHits2 Functions GUI2.m, textBox1.m, textBox2.m, ChangeptsFusionDetector1.m, ChangeptsFusionDetector2m, DockingShared.m and getkey.m are required for fusionDetector2_0_8.

## /HMMbatchscript ##
matlab scripts to perform HMM analysis on single molecule trace files. 

Single file version:
`HMM_single_file_atb.m`

Edit the name of the filename (text file) that contains the trace:
`path=['<enter filename here>'];`


Batch version:
`HMM_batch_atb.m`

Edit the name of the directory that contains the .txt files with traces:
`path = '<enter pathname here>';`

For each displayed trace and HMM analysis, the user should pick a number between 0 and 9 specifying the number of jumps in the trace file. A spreadsheet is generated:
`film2test.xlsx`
that contains the number of jumps. 


## /smCamera_conversion/smm_conversion ##

matlab script file to convert smCamera .smm trajectory files to .tif format.
`smm2tif_M_atb.m` 

Edit the name of the directory that contains the .smm files:
`path = '<enter pathname here>';`
	
and then run in matlab. For each .smm file, a .tif file is created within the same directory.


## /smCamera_conversion/smt_conversion ##

matlab script file to convert smCamera .smt trace files (containing traces for each detected spot) to text format: `ssmt2txtFiles_atb.m` 

Alternative version that does not use double __ in resulting file names: `ssmt2txtFiles_atb2.m` 

Edit the name of the directory that contains the .smt files:
`path = '<enter pathname here>';`

and then run in matlab. For each .smt file a subdirectory is created that contains the text files for each of the traces.

## /smFRET_scripts ##

This directory contains scripts necessary to analyze and process the raw .pma files (written by smCamera, Lee, K.S., Ha, T. smCamera: all-in-one software package for single-molecule data acquisition and data analysis. J. Korean Phys. Soc. 86, 1–13 (2025), https://doi.org/10.1007/s40042-024-01243-z .  

pma_to_tiff.py: A python script used to convert .pma files to .tif files. These .tif files can be generated by using the pma_to_tiff.py file with the following command python ./pma_to_tiff.py x.pma --debug --normalize. 

smt_or_traces_converter.py:  This python script file will dump the raw contents of an .smt or .traces file into a .txt file for manual inspection of the raw contents of the file. This can be used to manually inspect the file if desired. 

traces_to_itx.m: This MATLAB script can be used to analyze .pma files (background correction, peak correlation, and generation of putative traces) the .traces file to individual .itx files (also allows for selection of good/bad traces). 
 
guiForPrime.mlapp: This MATLAB reads the raw .pma files, and then allows the user to accept/reject them manually, and convert them to .traces file. The guiForPrimeUserManual.pdf is a step-ty-step tutorial (courtesy of Keith Weninger, NC State). 



