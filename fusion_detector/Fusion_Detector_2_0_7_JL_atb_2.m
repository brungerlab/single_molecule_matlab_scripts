3%Fusion Detector

% This script imports traces from putative fusions events and filters these
% events by detecting peaks and analyzing the surrounding areas. The traces
% for the remaining putative fusion events are plotted one at a time and
% the user confirms or rejects each hit. The final hits are stored in a
% variable called "confirmedHits." If you have two channels, channel two
% hits are stored in confirmedHits2 Functions GUI2.m, textBox1.m,
% textBox2.m, and getkey.m are required for fusionDetector.

%% To Do List
% (x) Comment code
% (x) Write channel 2 code
% () Find a way to allow tandem analysis of data
% () Write publish histograms code () See if I can work functions into main codedocking_
% (?) Hide get key box
% (x) Tile histograms


%% Cleaning up the workspace

% All figures are closed. All variables are cleared except those involving
% file selection. Beep is turned off cause it's annoying.

close all
clearvars -except fileName fileType Chan1 Chan2
beep off

%% Setting thresholds and selecting file for analysis

% Checks to see if the file selection variables are still around from a
% previous analysis. 
inputTest= exist('fileName','var')+exist('fileType','var');
cancel=0; 

% Calls the GUI that allows for the input of various thresholds and file
% types. If the file selection variables are around from a prevoius run,
% those will be inputed in as default to avoid needless re-entry.

if inputTest>1
    GUI2(fileName, fileType)
else 
    fileName='new';
    fileType='new*';
    GUI2(fileName, fileType)
end
 
% An escape route if you press cancel in the GUI
if cancel>0 
    return 
end
 
% identify the folder that your data is in
fileDirectory=[uigetdir(),'/'];

% Below are some general thresholds that we've left unchanged for a while,
% so they're coded in. 

% Select whether to define peaks with a post baseline
post=1; %str2num(inputVal{5});                                                                                                                                                                                                                                                                                                                                                                   ;
 
% Select bin size for histograms (seconds)
binSize=1;
 
% Select "confirmedHits" noise level
hitnoise=2;
 
baseline=1;
 
%% Organizes data into a variable called rawTraces

% A structure that stores information about each trace
dataName=dir([fileDirectory, fileType]);

% An error message that pops up if the selected directory is empty
if length(dataName)<1
    msgbox('No files in selected directory','Error')
    return
end
 
% A data structure whose length is the number of traces and that contains 3
% fields: fluorescence measurements, header names, and a redundant header
% names field. The fluorescent mesasurements field has 5 columns: time,
% channel 1 intensity, channel 1 background, channel 2 intensity, and
% channel 2 background. (Note: this seems like it could be cleaned up,
% dataName might be able to be incorporated into dataStruct.)

for i=1:length(dataName)
     dataStruct(i)=importdata([fileDirectory,dataName(i).name]);
end
 
% This is the beginning of organizing the data into usable variables. This
% step takes the time measurements and puts them into the first column of
% rawTraces.
rawTraces(:,1)=dataStruct(1).data(:,1);
 
% This step puts the fluorsecence measurements into rawTraces. i causes it
% to loop through all of the traces. j goes through the 4 measurements
% (channel 1, channel 1 background, channel 2, and channel 2 background). k
% moves it down a column at a time. 
k=2;
for i=1:length(dataStruct)
    for j=1:4
    	rawTraces(:,k)=dataStruct(i).data(:,j+1);
    	k=k+1;
    end
end

if Chan1>0

%% Background correction

% Loops through all of the traces and substracts channel 1 background from
% channel 1. This background correction is stored in a variable called
% chan1Background.
for i=1:length(dataStruct)
   chan1Background(:,i)=(dataStruct(i).data(:,2)-dataStruct(i).data(:,3));
end
 
 
%% Baseline correction

% In order to normalize the traces and control for variance in initial
% levels of fluorescence, the first 25 frames are averaged and this value
% is substracted from each frame. This is stored in a variable called
% chan1Background.
chan1Baseline=chan1Background;
[sizeChan1x,n]=size(chan1Background);
EndCheck=[];
BeginCheck=[];
BeginStdev=[];
 
if baseline>0
for i=1:length(dataStruct)
    for j=1:sizeChan1x
        chan1Baseline(j,i)=chan1Baseline(j,i)-mean(chan1Background(1:25,i));
        EndCheck(1,i)=mean(chan1Baseline(sizeChan1x-25:sizeChan1x,i));
        EndCheckStdev(1,i)=std(chan1Baseline(sizeChan1x-25:sizeChan1x,i));
        BeginCheck(1,i)=mean(chan1Baseline(1:25,i));
        BeginStdev(1,i)=std(chan1Baseline(1:25,i));
    end
end
end
 
if baseline>0
for i=1:length(dataStruct)
    for j=1:sizeChan1x
        chan1Baseline(j,i)=chan1Baseline(j,i)-mean(chan1Background(1:25,i));
    end
end
end
 
%% Detect peaks

% This is the core of the function. Putative hits are detected by a variety
% of thresholds. 
indexData=0;
 
if post>0
for i=1:length(dataStruct)
    z=1;
    for j=1:sizeChan1x
    	if j-peakDetBL1-preBaseline1>0 && j+peakDetpk1+peakDetPostBL1+peakDetDelay1<sizeChan1x
            % For all points within a single trace, the following values
            % are calculated
            peak(j,i)=mean(chan1Baseline(j:j+peakDetpk1-1,i));
            baselineVal(j,i)=mean(chan1Baseline(j-peakDetBL1:j-1,i));
            noiseThresh(j,i)=noiseMul1*std(chan1Baseline(j-peakDetBL1:j-1,i));
        	delayAmplitude(j,i)=mean(chan1Baseline(j+peakDetDelay1:j+peakDetDelay1+peakDetPostBL1,i));
            delayNoiseThresh(j,i)=noiseMulDelay1*std(chan1Baseline(j-peakDetBL1:j-1,i));
            amplitude(j,i)=peak(j,i)-baselineVal(j,i);
            stdPeak(j,i)=std(chan1Baseline(j:j+peakDetpk1-1,i));
        	PreBaselineVal(j,i)=mean(chan1Baseline(j-peakDetBL1-preBaseline1:j-peakDetBL1,i));
            	% This is the actual peak detection. It stores the index
            	% infomation for the putative hits into a variable called
            	% indexData.
                if peak(j,i)>baselineVal(j,i)+noiseThresh(j,i) && delayAmplitude(j,i)>baselineVal(j,i)+delayNoiseThresh(j,i) && stdPeak(j,i)<hitnoise*(std(chan1Baseline(j-peakDetBL1:j-1,i))) && PreBaselineVal(j,i)>baselineVal(j,i)-noiseThresh(j,i) && EndCheck(1,i)>BeginCheck(1,i)+BeginStdev(1,i); 
                	indexData(z,i)=j;
                	z=z+1;
            	end
    	end
    end
end
end
   
%% Remove redundant hits	
 
% Because the algorithm finds hits based on thresholds, there can be
% redundancy in the hit detection. This section goes through the putative
% hits and removes the ones that are within 10 frames of each other.
for i=1:size(indexData,2)
    for j=1:size(indexData,1)-1;
    	for k=1:size(indexData,1)-j;
        	if indexData(j,i)-indexData(j+k,i)>-10;
            	indexData(j+k,i)=0;
        	end
    	end
    end
end
 
%% Organize data into "putativeHits" structure
 
% This section organizes the putative hits from indexData and organizes
% them into a structure called "putativeHits." This variable has 5 fields
% called name, time, amplitude, datasetIndex, and timeIndex.
[row, col]=find(indexData>0);
putativeHits=struct('name',{dataName(col).name},'time', [], 'amplitude', [], 'datasetIndex', [], 'timeIndex', []);
 
for i=1:length(row)
    time(i)=rawTraces(indexData(row(i),col(i)),1);
    amp(i)=amplitude(indexData(row(i),col(i)), col(i));
    putativeHits(i).time=time(i);
    putativeHits(i).amplitude=amp(i);
    putativeHits(i).datasetIndex=col(i);
    putativeHits(i).timeIndex=indexData(row(i),col(i),1);
end
 
%% Plot data and select true hits from putative hit list

% This allows the user to go through the putative hits and reject false
% positives. Using the keyboard, the user can navigate through plotted
% traces. Example traces can be saved into a structure called
% "exampleTraces." 
 
if ploton>0
    % Notifies the user how many putative hits there are and provides
    % instructions for navigating through the traces.
    textBox1(putativeHits)
    % Sets up the variables necessary for data storage and loop indices.
    falsePosNum=[];
    exampleTraces=struct('name',[],'time', [], 'amplitude', [], 'datasetIndex', [], 'timeIndex', []);
    ETLoop=1;
    i=1;
    % Goes through the traces in putativeHits and plots them one at a time. The
    % variable "i" indicates which traces is being plotted.
    while i<=length(putativeHits)
    	if i>0
        	% Plots the current trace
            figPlot=figure(i+3);
            set(figPlot,'name','Hit?','numbertitle','off')
        	plot(rawTraces(:,1), (chan1Baseline(:,putativeHits(i).datasetIndex)), 'k', 'LineWidth', 1.5)
        	hold on
            plot((rawTraces(putativeHits(i).timeIndex,1)),(chan1Baseline(putativeHits(i).timeIndex,putativeHits(i).datasetIndex)), 'r.', 'markers',38)
        	ylabel('Amplitude');
        	xlabel('Time(s)');
			%
			% ATB, Nov. 13, 2021
			titlename=putativeHits(i).name;
            titlename=strrep(titlename,"_","\_");
        	title([titlename, ' ', 'at ', num2str(putativeHits(i).time), ' sec'])
			%        	title([putativeHits(i).name, ' ', 'at ', num2str(putativeHits(i).time), ' sec'])
			%
        	
            % Waits for the user to input a key press
        	key=getkey();
        	
            % The esc key exits the function
            if key==27 
            	return
        	
            % The backspace key stores the index of the removed trace in a
            % variable called "falsePosNum."
            elseif key==8 
            	falsePosNum=[falsePosNum, i];
            	i=i+1;
        	
            % The s key stores the current trace in a variable called
        	% "exampleTraces."
            elseif key==115 
                exampleTraces(ETLoop).name=putativeHits(i).name;
                exampleTraces(ETLoop).time=putativeHits(i).time;
                exampleTraces(ETLoop).amplitude=putativeHits(i).amplitude;
                exampleTraces(ETLoop).datasetIndex=putativeHits(i).datasetIndex;
                exampleTraces(ETLoop).timeIndex=putativeHits(i).timeIndex;
            	ETLoop=ETLoop+1;
                i=i+1;
        	
            % The right arrow confirms that the current trace is good.
            elseif key==29 
            	i=i+1;
        	
            % The left arrow will remove a trace from "falsePosNum" if the
            % user has made a mistake.
            elseif key==28
            	i=i-1;
            	falsePosNum(falsePosNum==i)=[];
        	end
        	close
    	else
        	i=1;
        end
        
        % Once the user has checked all of the traces, a prompt will appear
        % asking if the user is done looking through the traces. If not,
        % the user will be returned to the last trace.
        if i==length(putativeHits)+1
            textBox2()
            if cancel3<2
                i=i-1;
                falsePosNum(falsePosNum==i)=[];              
            end
        end
    end
   
end
    
%% Remove false positives

% Loops through "falsePosNum" which stores the index for the false
% positives identified by the user. These traces are removed from 
% "putativeHits."
confirmedHits=putativeHits;
if ploton>0
    if falsePosNum>0
        for i=length(falsePosNum):-1:1
            confirmedHits(falsePosNum(i))=[];
        end
    end
end
%% Create histograms of hit times, corrected hit times, and hit amplitudes.
 
% If there are no confirmed hits, a warning message will pop up. 
if length(confirmedHits)<1
    msgbox('No events detected','Uh oh?')
else
   % The time and amplitude of each confirmed are stored in variables called
% "hitTime" and "hitAmp" respectively. This is the only way I could get the
% later histograms to plot properly. 
for i=1:length(confirmedHits)
    hitTime(i)=confirmedHits(i).time;
    hitAmp(i)=confirmedHits(i).amplitude;
end

% This is the actual plotting of the three histograms (if "Plot Histograms"
% is checked in the GUI).
if histon>0
    
    % Plots a histogram of the hit times.
    hist1= figure('Position', [250 800 550 450]);
    h=histogram(hitTime, 'BinWidth', binSize);
    ylabel('# of Hits');
    xlabel('Time(s)');
    [maxVal, maxBin]=max(h.Values);
    set(hist1,'name','Channel 1 Hit Times','numbertitle','off')
    pause(0.1);
    
    % Set the first hit to 0 s by subtracting it from all of the hit times.
    hitTimeCorrected=hitTime;
    minTimeCorrected=min(hitTimeCorrected);
    for i=1:length(hitTimeCorrected)
        hitTimeCorrected(i)=hitTimeCorrected(i)-minTimeCorrected;
    end
    
    % Plots a histogram of the corrected hit times.
    hist2= figure('Position', [810 800 550 450]);
    histogram(hitTimeCorrected, 'BinWidth', binSize);
    ylabel('# of Hits');
    xlabel('Time(s)');
    set(hist2,'name','Channel 1 Corrected Hit Times','numbertitle','off')

    pause(0.1);
    
    % Plots a histogram of hit amplitudes.
    hist3=figure('Position', [1370 800 550 450]);
    histogram(hitAmp,'BinWidth',50);
    set(hist3,'name','Channel 1 Hit Amplitudes','numbertitle','off')

    pause(0.1);
    
end 
end


end

%% Channel 2 peak detection

% This section repeats the previous peak detection for channel 2. 

if Chan2>0

%% Background correction

% Loops through all of the traces and substracts channel 2 background from
% channel 2. This background correction is stored in a variable called
% chan2Background.
for i=1:length(dataStruct)
   chan2Background(:,i)=(dataStruct(i).data(:,4)-dataStruct(i).data(:,5));
end
 
 
%% Baseline correction

% In order to normalize the traces and control for variance in initial
% levels of fluorescence, the first 25 frames are averaged and this value
% is substracted from each frame. This is stored in a variable called
% chan2Background.
chan2Baseline=chan2Background;
[sizeChan1x,n]=size(chan2Background);
EndCheck=[];
BeginCheck=[];
BeginStdev=[];
 
if baseline>0
for i=1:length(dataStruct)
    for j=1:sizeChan1x
        chan2Baseline(j,i)=chan2Baseline(j,i)-mean(chan2Background(1:25,i));
        EndCheck(1,i)=mean(chan2Baseline(sizeChan1x-25:sizeChan1x,i));
        EndCheckStdev(1,i)=std(chan2Baseline(sizeChan1x-25:sizeChan1x,i));
        BeginCheck(1,i)=mean(chan2Baseline(1:25,i));
        BeginStdev(1,i)=std(chan2Baseline(1:25,i));
    end
end
end

if baseline>0
for i=1:length(dataStruct)
    for j=1:sizeChan1x
        if j>3 && j<sizeChan1x-4
        peak(j,i)=mean(chan2Baseline(j-peakDetpk2*(3/8):j+peakDetpk2*(1/2),i));%changed to an average of 8 starting at -3 to +4
    end
        
    end
end
end

 
%% Detect peaks

% This is the core of the function. Putative hits are detected by a variety
% of thresholds. 
indexData=0;
 
if post>0
for i=1:length(dataStruct)
    z=1;
    for j=1:sizeChan1x
    	if j-peakDetBL2-preBaseline2>0 && j+peakDetpk2+peakDetPostBL2+peakDetDelay2<sizeChan1x
            % For all points within a single trace, the following values
            % are calculated
            % moved peak calculation from here
            baselineVal(j,i)=mean(chan2Baseline(j-6-peakDetBL2:j-7,i));%changed to offset by -6 frames
            noiseThresh(j,i)=noiseMul2*std(chan2Baseline(j-6-peakDetBL2:j-7,i));%changed to offset by -6 frames
        	delayAmplitude(j,i)=mean(chan2Baseline(j+peakDetDelay2:j+peakDetDelay2+peakDetPostBL2-1,i));%changed to offset by 28 frames
            delayNoiseThresh(j,i)=noiseMulDelay2*std(chan2Baseline(j-6-peakDetBL2:j-7,i));%changed to offset by -6 frames
            amplitude(j,i)=peak(j,i)-baselineVal(j,i);
            stdPeak(j,i)=std(chan2Baseline(j-peakDetpk2*(3/8):j+peakDetpk2*(1/2),i));%changed to match the peak values
        	PreBaselineVal(j,i)=mean(chan2Baseline(j-peakDetBL2-preBaseline2:j-peakDetBL2,i));%NOT changed
            	% This is the actual peak detection. It stores the index
            	% infomation for the putative hits into a variable called
            	% indexData.
                if peak(j,i)>baselineVal(j,i)+noiseThresh(j,i) && delayAmplitude(j,i)>baselineVal(j,i)+delayNoiseThresh(j,i) && stdPeak(j,i)<hitnoise*(stdPeak(j,i)) && PreBaselineVal(j,i)>baselineVal(j,i)-noiseThresh(j,i) && all(delayAmplitude(j-3:j,i)>baselineVal(j-3:j,i)+delayNoiseThresh(j-3:j,i)) && EndCheck(1,i)>BeginCheck(1,i)+BeginStdev(1,i) && (baselineVal(j,i))>BeginCheck(1,i)-(BeginStdev(1,i)*noiseMul2) && (EndCheck(1,i))>(PreBaselineVal(j,i)+noiseThresh(j,i)) && mean(peak(j-14:j-6,i))>BeginCheck(1,i)-BeginStdev(1,i) && EndCheck(1,i)>baselineVal(j,i)+noiseThresh(j,i)
                	indexData(z,i)=j;
                	z=z+1;
             	end
        end
    end
end
end
   
%% Remove redundant hits	
 
% Because the algorithm finds hits based on thresholds, there can be
% redundancy in the hit detection. This section goes through the putative
% hits and removes the ones that are within 10 frames of each other.
for i=1:size(indexData,2)
    for j=1:size(indexData,1)-1
    	for k=1:size(indexData,1)-j
        	if indexData(j,i)-indexData(j+k,i)>-10 
            	indexData(j+k,i)=0;
        	end
    	end
    end
end
 
%% Organize data into "putativeHits" structure
 
% This section organizes the putative hits from indexData and organizes
% them into a structure called "putativeHits2." This variable has 5 fields
% called name, time, amplitude, datasetIndex, and timeIndex.
[row, col]=find(indexData>0);
putativeHits2=struct('name',{dataName(col).name},'time', [], 'amplitude', [], 'datasetIndex', [], 'timeIndex', []);
 
for i=1:length(row)
    time(i)=rawTraces(indexData(row(i),col(i)),1);
    amp(i)=amplitude(indexData(row(i),col(i)), col(i));
    putativeHits2(i).time=time(i);
    putativeHits2(i).amplitude=amp(i);
    putativeHits2(i).datasetIndex=col(i);
    putativeHits2(i).timeIndex=indexData(row(i),col(i),1);
end
 
%% Plot data and select true hits from putative hit list

% This allows the user to go through the putative hits and reject false
% positives. Using the keyboard, the user can navigate through plotted
% traces. Example traces can be saved into a structure called
% "exampleTraces2." 
 

% Notifies the user how many putative hits there are and provides
% instructions for navigating through the traces.
textBox1(putativeHits2)
% Sets up the variables necessary for data storage and loop indices.
falsePosNum=[];
exampleTraces2=struct('name',[],'time', [], 'amplitude', [], 'datasetIndex', [], 'timeIndex', []);
ETLoop=1;
i=1;
% Goes through the traces in putativeHits2 and plots them one at a time. The
% variable "i" indicates which traces is being plotted.
while i<=length(putativeHits2)
    if i>0
        % Plots the current trace
        figPlot=figure(i+3);
        set(figPlot,'name','Hit?','numbertitle','off')
        plot(rawTraces(:,1), (chan2Baseline(:,putativeHits2(i).datasetIndex)), 'k', 'LineWidth', 1.5)
        hold on
        plot((rawTraces(putativeHits2(i).timeIndex,1)),(chan2Baseline(putativeHits2(i).timeIndex,putativeHits2(i).datasetIndex)), 'r.', 'markers',38)
        ylabel('Amplitude');
        xlabel('Time(s)');
        title([putativeHits2(i).name, ' ', 'at ', num2str(putativeHits2(i).time), ' sec'])
        
        % Waits for the user to input a key press
        key=getkey();
        
        % The esc key exits the function
        if key==27
            return
            
            % The backspace key stores the index of the removed trace in a
            % variable called "falsePosNum."
        elseif key==8
            falsePosNum=[falsePosNum, i];
            i=i+1;
            
            % The s key stores the current trace in a variable called
            % "exampleTraces2."
        elseif key==115
            exampleTraces2(ETLoop).name=putativeHits2(i).name;
            exampleTraces2(ETLoop).time=putativeHits2(i).time;
            exampleTraces2(ETLoop).amplitude=putativeHits2(i).amplitude;
            exampleTraces2(ETLoop).datasetIndex=putativeHits2(i).datasetIndex;
            exampleTraces2(ETLoop).timeIndex=putativeHits2(i).timeIndex;
            ETLoop=ETLoop+1;
            i=i+1;
            
            % The right arrow confirms that the current trace is good.
        elseif key==29
            i=i+1;
            
            % The left arrow will remove a trace from "falsePosNum" if the
            % user has made a mistake.
        elseif key==28
            i=i-1;
            falsePosNum(falsePosNum==i)=[];
        end
        close
    else
        i=1;
    end
    
    % Once the user has checked all of the traces, a prompt will appear
    % asking if the user is done looking through the traces. If not,
    % the user will be returned to the last trace.
    if i==length(putativeHits2)+1
        textBox2()
        if cancel3<2
            i=i-1;
            falsePosNum(falsePosNum==i)=[];
        end
    end
end
   

    
%% Remove false positives

% Loops through "falsePosNum" which stores the index for the false
% positives identified by the user. These traces are removed from 
% "putativeHits2."
confirmedHits2=putativeHits2;
if falsePosNum>0
    for i=length(falsePosNum):-1:1
        confirmedHits2(falsePosNum(i))=[];
    end
end

%% Create histograms of hit times, corrected hit times, and hit amplitudes.
 
% If there are no confirmed hits, a warning message will pop up. 
if length(confirmedHits2)<1
    msgbox('No events detected','Uh oh?')
    return
end

% The time and amplitude of each confirmed are stored in variables called
% "hitTime2" and "hitAmp2" respectively. This is the only way I could get the
% later histograms to plot properly. 
for i=1:length(confirmedHits2)
    hitTime2(i)=confirmedHits2(i).time;
    hitAmp2(i)=confirmedHits2(i).amplitude;
end

% This is the actual plotting of the three histograms (if "Plot Histograms"
% is checked in the GUI).
  
% Plots a histogram of the hit times.
hist4=figure('Position', [250 300 550 450]);
h=histogram(hitTime2, 'BinWidth', binSize);
ylabel('# of Hits');
xlabel('Time(s)');
[maxVal, maxBin]=max(h.Values);
set(hist4,'name','Channel 2 Hit Times','numbertitle','off')

pause(0.1);

% Set the first hit to 0 s by subtracting it from all of the hit times.
hitTimeCorrected2=hitTime2;
minTimeCorrected2=min(hitTimeCorrected2);
for i=1:length(hitTimeCorrected2)
    hitTimeCorrected2(i)=hitTimeCorrected2(i)-minTimeCorrected2;
end

% Plots a histogram of the corrected hit times.
hist5=figure('Position', [810 300 550 450]);
histogram(hitTimeCorrected2, 'BinWidth', binSize);
ylabel('# of Hits');
xlabel('Time(s)');
set(hist5,'name','Channel 2 Corrected Hit Times','numbertitle','off')
pause(0.1);

% Plots a histogram of hit amplitudes.
hist6=figure('Position', [1370 300 550 450]);
histogram(hitAmp2,'BinWidth',50);
set(hist6,'name','Channel 2 Hit Amplitudes','numbertitle','off')

pause(0.1);
    

end
%% Channel 2 quick peak detection.
% This section is a shortcut in which Channel 2 is averaged together
% rather then analyzed for an increase in fluorescence.

if Chan2Short>0
%% Background correction

% Loops through all of the traces and substracts channel 2 background from
% channel 2. This background correction is stored in a variable called
% chan2Background.
for i=1:length(dataStruct)
   chan2Background(:,i)=dataStruct(i).data(:,4);
end
 
 
%% Baseline correction

% In order to normalize the traces and control for variance in initial
% levels of fluorescence, the first 25 frames are averaged and this value
% is substracted from each frame. This is stored in a variable called
% chan2Backg
chan2Baseline=chan2Background;
[sizeChan1x,n]=size(chan2Background);
EndCheck=[];
BeginCheck=[];
BeginStdev=[];
 
if baseline>0
for i=1:length(dataStruct)
    for j=1:sizeChan1x
        chan2Baseline(j,i)=chan2Baseline(j,i)-mean(chan2Background(1:25,i));
        EndCheck(1,i)=mean(chan2Baseline(sizeChan1x-25:sizeChan1x,i));
        EndCheckStdev(1,i)=std(chan2Baseline(sizeChan1x-25:sizeChan1x,i));
        BeginCheck(1,i)=mean(chan2Baseline(1:25,i));
        BeginStdev(1,i)=std(chan2Baseline(1:25,i));
    end
end
end

if baseline>0
for i=1:length(dataStruct)
    for j=1:sizeChan1x
        if j>3 && j<sizeChan1x-4
        peak(j,i)=mean(chan2Baseline(j-peakDetpk2*(3/8):j+peakDetpk2*(1/2),i));%changed to an average of 8 starting at -3 to +4
    end
        
    end
end
end

if Chan2Short>0 
    for i=1:sizeChan1x
        chan2mean(i,1)=mean(chan2Baseline(i,:));
        EndCheckmean=mean(EndCheck(1,:));
        BeginCheckmean=mean(BeginCheck(1,:));
        BeginStdevmean=mean(BeginStdev(1,:));
    end
end
    

%% Detect peaks

% This is the core of the function. Putative hits are detected by a variety
% of thresholds. 
indexData=0;
 
if post>0
    for z=1;
    for j=1:sizeChan1x
    	if j-peakDetBL2-preBaseline2>0 && j+peakDetpk2+peakDetPostBL2+peakDetDelay2<sizeChan1x
            % For all points within a single trace, the following values
            % are calculated
            % moved peak calculation from here
            baselineVal(j,1)=mean(chan2mean(j-6-peakDetBL2:j-7,1));%changed to offset by -6 frames
            noiseThresh(j,1)=noiseMul2*std(chan2mean(j-6-peakDetBL2:j-7,1));%changed to offset by -6 frames
        	delayAmplitude(j,1)=mean(chan2mean(j+peakDetDelay2:j+peakDetDelay2+peakDetPostBL2-1,1));%changed to offset by 28 frames
            delayNoiseThresh(j,1)=noiseMulDelay2*std(chan2mean(j-6-peakDetBL2:j-7,1));%changed to offset by -6 frames
            amplitude(j,1)=peak(j,1)-baselineVal(j,1);
            stdPeak(j,1)=std(chan2mean(j-peakDetpk2*(3/8):j+peakDetpk2*(1/2),1));%changed to match the peak values
        	PreBaselineVal(j,1)=mean(chan2mean(j-peakDetBL2-preBaseline2:j-peakDetBL2,1));%NOT changed
            	% This is the actual peak detection. It stores the index
            	% infomation for the putative hits into a variable called
            	% indexData.
                if chan2mean(j,1)>baselineVal(j,1)+noiseThresh(j,1) && delayAmplitude(j,1)>baselineVal(j,1)+delayNoiseThresh(j,1) && stdPeak(j,1)<hitnoise*(stdPeak(j,1)) && PreBaselineVal(j,1)>baselineVal(j,1)-noiseThresh(j,1) && all(delayAmplitude(j-3:j,1)>baselineVal(j-3:j,1)+delayNoiseThresh(j-3:j,1))                	
                    indexData(z,1)=j;
                	z=z+1;
            	end
        end
  
    end
    end
end


    
%% Remove redundant hits	
 
% Because the algorithm finds hits based on thresholds, there can be
% redundancy in the hit detection. This section goes through the putative
% hits and removes the ones that are within 10 frames of each other.

    for j=1:size(indexData,1)-1
    	for k=1:size(indexData,1)-j
        	if indexData(j,1)-indexData(j+k,1)>-10 
            	indexData(j+k,1)=0;
        	end
    	end
    end

 
%% Organize data into "putativeHits" structure
 
% This section organizes the putative hits from indexData and organizes
% them into a structure called "putativeHits2." This variable has 5 fields
% called name, time, amplitude, datasetIndex, and timeIndex.
[row, col]=find(indexData>0);
putativeHits2=struct('name',{dataName(col).name},'time', [], 'amplitude', [], 'datasetIndex', [], 'timeIndex', []);
 
for i=1:length(row)
    time(i)=rawTraces(indexData(row(i),col(i)),1);
    amp(i)=amplitude(indexData(row(i),col(i)), col(i));
    putativeHits2(i).time=time(i);
    putativeHits2(i).amplitude=amp(i);
    putativeHits2(i).datasetIndex=col(i);
    putativeHits2(i).timeIndex=indexData(row(i),col(i),1);
end
 
%% Plot data and select true hits from putative hit list

% This allows the user to go through the putative hits and reject false
% positives. Using the keyboard, the user can navigate through plotted
% traces. Example traces can be saved into a structure called
% "exampleTraces2." 
 

% Notifies the user how many putative hits there are and provides
% instructions for navigating through the traces.
textBox1(putativeHits2)
% Sets up the variables necessary for data storage and loop indices.
falsePosNum=[];
exampleTraces2=struct('name',[],'time', [], 'amplitude', [], 'datasetIndex', [], 'timeIndex', []);
ETLoop=1;
i=1;
% Goes through the traces in putativeHits2 and plots them one at a time. The
% variable "i" indicates which traces is being plotted.
while i<=length(putativeHits2)
    if i>0
        % Plots the current trace
        figPlot=figure(i+3);
        set(figPlot,'name','Hit?','numbertitle','off')
        plot(rawTraces(:,1), (chan2mean(:,putativeHits2(i).datasetIndex)), 'k', 'LineWidth', 1.5)
        hold on
        plot((rawTraces(putativeHits2(i).timeIndex,1)),(chan2mean(putativeHits2(i).timeIndex,putativeHits2(i).datasetIndex)), 'r.', 'markers',38)
        ylabel('Amplitude');
        xlabel('Time(s)');
		%
		% ATB, Nov 13, 2021
		titlename=putativeHits2(i).name;
        titlename=strrep(titlename,"__","\_\_");
        titlename=strrep(titlename,"_","\_");
        title([titlename, ' ', 'at ', num2str(putativeHits2(i).time), ' sec'])
		%        title([putativeHits2(i).name, ' ', 'at ', num2str(putativeHits2(i).time), ' sec'])
		%
        
        % Waits for the user to input a key press
        key=getkey();
        
        % The esc key exits the function
        if key==27
            return
            
            % The backspace key stores the index of the removed trace in a
            % variable called "falsePosNum."
        elseif key==8
            falsePosNum=[falsePosNum, i];
            i=i+1;
            
            % The s key stores the current trace in a variable called
            % "exampleTraces2."
        elseif key==115
            exampleTraces2(ETLoop).name=putativeHits2(i).name;
            exampleTraces2(ETLoop).time=putativeHits2(i).time;
            exampleTraces2(ETLoop).amplitude=putativeHits2(i).amplitude;
            exampleTraces2(ETLoop).datasetIndex=putativeHits2(i).datasetIndex;
            exampleTraces2(ETLoop).timeIndex=putativeHits2(i).timeIndex;
            ETLoop=ETLoop+1;
            i=i+1;
            
            % The right arrow confirms that the current trace is good.
        elseif key==29
            i=i+1;
            
            % The left arrow will remove a trace from "falsePosNum" if the
            % user has made a mistake.
        elseif key==28
            i=i-1;
            falsePosNum(falsePosNum==i)=[];
        end
        close
    else
        i=1;
    end
    
    % Once the user has checked all of the traces, a prompt will appear
    % asking if the user is done looking through the traces. If not,
    % the user will be returned to the last trace.
    if i==length(putativeHits2)+1
        textBox2();
        if cancel3<2
            i=i-1;
            falsePosNum(falsePosNum==i)=[];
        end
    end
end
   

    
%% Remove false positives

% Loops through "falsePosNum" which stores the index for the false
% positives identified by the user. These traces are removed from 
% "putativeHits2."
confirmedHits2=putativeHits2;
if falsePosNum>0
    for i=length(falsePosNum):-1:1
        confirmedHits2(falsePosNum(i))=[];
    end
end

%% Create histograms of hit times, corrected hit times, and hit amplitudes.
 
% If there are no confirmed hits, a warning message will pop up. 
if length(confirmedHits2)<1
    msgbox('No events detected','Uh oh?')
    return
end

% The time and amplitude of each confirmed are stored in variables called
% "hitTime2" and "hitAmp2" respectively. This is the only way I could get the
% later histograms to plot properly. 
for i=1:length(confirmedHits2)
    hitTime2(i)=confirmedHits2(i).time;
    hitAmp2(i)=confirmedHits2(i).amplitude;
end

% This is the actual plotting of the three histograms (if "Plot Histograms"
% is checked in the GUI).
  
% Plots a histogram of the hit times.
hist4=figure('Position', [250 300 550 450]);
h=histogram(hitTime2, 'BinWidth', binSize);
ylabel('# of Hits');
xlabel('Time(s)');
[maxVal, maxBin]=max(h.Values);
set(hist4,'name','Channel 2 Hit Times','numbertitle','off');

pause(0.1);

% Set the first hit to 0 s by subtracting it from all of the hit times.
hitTimeCorrected2=hitTime2;
minTimeCorrected2=min(hitTimeCorrected2);
for i=1:length(hitTimeCorrected2)
    hitTimeCorrected2(i)=hitTimeCorrected2(i)-minTimeCorrected2;
end


% Plots a histogram of the corrected hit times.
hist5=figure('Position', [810 300 550 450]);
histogram(hitTimeCorrected2, 'BinWidth', binSize);
ylabel('# of Hits');
xlabel('Time(s)');
set(hist5,'name','Channel 2 Corrected Hit Times','numbertitle','off')
pause(0.1); 

% Plots a histogram of hit amplitudes.
hist6=figure('Position', [1370 300 550 450]);
histogram(hitAmp2,'BinWidth',50);
set(hist6,'name','Channel 2 Hit Amplitudes','numbertitle','off')

pause(0.1);
fileDir=[fileDirectory, fileName];
save(fileDir);

end

fileDir=[fileDirectory, fileName];
save(fileDir)

% Saves the matlab file with all of the variables in the same folder as the
% raw traces and called fileName.


