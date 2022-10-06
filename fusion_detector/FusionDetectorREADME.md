Fusion Detector 2_0_8_JL.m

Tested with Matlab 2022c.

**Installed Matlab Add-Ons:**
*Statistics and Machine Learning Toolbox
Image Processing Toolbox
Signal Processing Toolbox*

Include these directories in the Matlab path:
Fusion_Detector_2_0_8.m
DockingShared.m
GUI2.m
textBox1.m
textBox2.m
ChangeptsFusionDetector1.m
ChangeptsFusionDetector2.m


Function and use:
Hello! And welcome to the Fusion Detector 2.0.8, created by Jeremy Leitz and John Peters in the Brunger lab @ Stanford university.

The fusion detector works to detect abrupt step-wise INCREASES in fluorescence data. Data is first subtracted by background, then analyzed for potential increases in fluorescence.  Increases are detected by combining two methods: First is the use of the findchangepts function added to Matlab 2017 (https://www.mathworks.com/help/signal/ref/findchangepts.html), the second is a sliding window analysis of the fluorescent traces looking for points that satisfy criteria determined by the user.  Those inputs are described briefly below and illustrated in FusionDetectorTheoryFig.png. The fusion detector assumes that the data files are organized as a 5 column text file where column #1 is time, #2 is fluorescence value of the first channel, #3 is the background fluorescence of the same channel, #4 is the fluorescence value of the second channel and #5 is the background fluorescence of the second channel. 

Upon running the detector, a gui should appear which will contain several variables that may be adjusted by the user to tailor the detector to the user's data.  
File Type: This is the prefix of title of your data, for example if your files are called Film1_data1, Film1_data2...  Then the input here would be "Film1_data*".  Please note that the "*" is required. 

Plot Traces checkbox:  When checked, the detector will plot each putative hit.  If left unchecked each putative hit will be considered a true hit. 

Plot Histograms checkbox: When checked this will plot 3 histograms (described below) after analyzing each channel. 

File Name:  This is what the output matlab structure file should be named.  For example "Film1_association"

Channel 1 checkbox: When checked will analzye Channel 1 according to the variables described on the left side of the gui.

Channel 2 checkbox: When checked will analyze Channel 2 according to the variables described on the right side of the gui. 

Channel 2 (quick) checkbox:  When checked the analysis will change from examining each trace of channel 2 to averaging all of the traces in channel 2 together and performing the analysis on that trace.  For our data, we include a soluble dye as an indicator for solution arrival in the channel.  Thus every trace in that channel will have the same signal.  This checkbox indicates that all the the traces in this channel will be more or less identical and speeds up processing time.  NOTE: THIS IS MUTUALLY EXCLUSIVE WITH THE CHANNEL 2 CHECKBOX, DO NOT SELECT BOTH.

Analyze button:  Will close the gui and open a file navigator to navigate to the directory containing your data.  

Cancel button: Exits the fusion detector.

Variables used to determine a hit:
These variables are on the left side of the gui and separated by channel allowing each channel to have different criteria, if desired.  This detector works as a sliding window checking if the average of several points, X, rises above a baseline value and if an average of points after X remain at a similarly elevated level (i.e. the increase is step-wise and not transient).

 '#' of Baseline Frames: The number of FRAMES used to calculate a baseline fluorescence value.
 
 # of Peak Frames: The number of FRAMES used to calculate a hit.
 
Noise Multiplier: How many standard deviations above the baseline must the hit value be to be considered a hit.   

Delay Gap Length:  How many frames after the putative hit should the trace be reanalyzed to ensure that it is not transient. NOTE: TAKE INTO CONSIDERATION ANY PHOTOBLEACHING THAT MAY OCCURE!

 # of Delay Frames:  How many frames should be used to calculate the intensity after the putative Hit
 
Delay Noise Multiplier: How many standard deviations above the baseline must the signal remain to qualify as a step-wise increase. 

 # Previous frames: How many frames should be skipped after a hit to avoid identifying the same hit multiple times. This is largely depends on the kinetics of your system. 
