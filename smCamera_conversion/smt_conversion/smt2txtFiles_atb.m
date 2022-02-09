% extract traces in .smt and save as .txt, a file or all file in a folder //MJ 2121
% included option to write as a time series file (only works for two channels) // ATB nov. 6, 2021

clear all
%% Settings 
%path = '/Users/brunger/Dropbox/archive/publications/2021/airway_project/source_code/smCamera_conversion/smt_conversion/';   % path for data folder
path = '/Users/brunger/Dropbox/archive/publications/2021/airway_project/ED Fig 5l-r trace file';   % path for data folder
AllFileInFolder = true;    %true/false (1/0): All smt files in the folder will be converted
filehead = 'hel1';          %filename for single file (ex. hel1)

fShowVariable = true;       %true/false (1/0): Whether to show column headings

timeSeries = true;	%true/false: if true, add time column (using the frameRate), and then show only rawSig_ch1, bg_ch1, rawSig_ch2, bg_ch2, sig_ch1, sig_ch2. This assumes a two-channel series.

if timeSeries
	columnHeadings = {'time [s]', 'rawSig_ch1', 'bg_ch1', 'rawSig_ch2', 'bg_ch2', 'sig_ch1', 'sig_ch2'}; 
else
	columnHeadings = {'sig_ch1', 'sig_ch2', 'rawSig_ch1', 'rawSig_ch2', 'bg_ch1', 'bg_ch2'}; 
end



%% Find smt files
cd(path);
if AllFileInFolder
    matfiles = dir(fullfile(path, '*.smt'));
    nfiles = length(matfiles)
else 
    nfiles = 1;
    matfiles(1).name = [filehead '.smt'];
end

%% convert a file or files
for f=1:nfiles

    %% Open smt file
    filename = matfiles(f).name;
    fid = fopen(filename);
    filenamehead = filename(1:end-4);

    %% Read [Section 1: Header]
    pos_start = ftell(fid)
    cntPeak = fread(fid, 1, 'uint32');
    cntFrame = fread(fid, 1, 'uint32');
    offset = fread(fid, 1, 'uint32');
    cntChan = fread(fid, 1, 'uint8');
    xSize = fread(fid, 1, 'uint16');
    ySize = fread(fid, 1, 'uint16');
    bgLevel = fread(fid, 1, 'uint32');
    scaler = fread(fid, 1, 'uint32');
    frameRate = fread(fid, 1, 'float');
    peakRadius = fread(fid, 1, 'float');
    peakSigma = fread(fid, 1, 'float');
    pos_HeaderEnd = ftell(fid)
		
	fprintf('pos_start= %d \n',pos_start);	
	fprintf('cntPeak= %d \n',cntPeak);	
	fprintf('cntFrame= %d \n',cntFrame);	
	fprintf('offset= %d \n',offset);
	fprintf('cntChan= %d \n',cntChan);
	fprintf('xSize= %d \n',xSize);
	fprintf('ySize= %d \n',ySize);
	fprintf('bgLevel= %d \n',bgLevel);
	fprintf('scaler= %d \n',scaler);
	fprintf('frameRate= %d \n',frameRate);
	fprintf('peakRadius= %d \n',peakRadius);
	fprintf('peakSigma= %d \n',peakSigma);
  
    
    %% Read [Section 2: Peaks]
    peaks_Xpos = NaN(cntPeak,cntChan,'single');
    peaks_Ypos = NaN(cntPeak,cntChan,'single');
    peaks_XSD = NaN(cntPeak,cntChan,'single');
    peaks_YSD = NaN(cntPeak,cntChan,'single');
    peaks_isGood = NaN(cntPeak,cntChan,'single');
    for i=1:cntPeak
       for j=1:cntChan
           peaks_Xpos(i,j) = fread(fid, 1, 'float');
           peaks_XSD(i,j) = fread(fid, 1, 'float');
           peaks_Ypos(i,j) = fread(fid, 1, 'float');
           peaks_YSD(i,j) = fread(fid, 1, 'float');
           peaks_isGood(i,j) = fread(fid, 1, 'uint32'); %check: uint8 for boolean
       end
    end  
    pos_PeaksEnd = ftell(fid)
    
    %% Read [Section 3: Data]   
    data1 = NaN(cntPeak,cntChan,cntFrame,'single');
    data2 = NaN(cntPeak,cntChan,cntFrame,'single');
	frame = NaN(cntPeak,cntFrame,'single');
    
    fseek(fid, offset,'bof');
    for i=1:cntPeak
        for j=1:cntChan
            for k=1:cntFrame
                data1(i,j,k) = fread(fid, 1, 'float'); %signal intensity
				frame(i,k) = k*frameRate/1000;
            end   
            for k=1:cntFrame
                data2(i,j,k) = fread(fid, 1, 'float'); %background intensity
            end 
        end
    end
    
    %% Check if the pointer reached the end 
%     pos_DataEnd = ftell(fid)
%     fseek(fid, 0 , 'eof');
%     pos_eof_file  = ftell(fid)

    %% Save trace files in a folder
    mkdir(filenamehead);
    cd([path filesep filenamehead])
    for i=1:cntPeak
        %signal data
        intensityRawSignal = squeeze(data1(i,:,:));
        intensityBackground = squeeze(data2(i,:,:));
        intensitySignal = intensityRawSignal-intensityBackground;
		if timeSeries
	        saveTable = array2table([frame(i,:)' intensityRawSignal(1,:)' intensityBackground(1,:)' intensityRawSignal(2,:)' intensityBackground(2,:)' intensitySignal(1,:)' intensitySignal(2,:)']);
 		else
	        saveTable = array2table([intensitySignal' intensityRawSignal' intensityBackground']);
 		end
        saveTable.Properties.VariableNames = columnHeadings;
        
        %peak position 
        Xpos1 = round(peaks_Xpos(i,1));
        Ypos1 = round(peaks_Ypos(i,1));
        Xpos2 = round(peaks_Xpos(i,2));
        Ypos2 = round(peaks_Ypos(i,2));
        
        saveFileName = [filenamehead '_' num2str(i) '__' num2str(Xpos1) '_' num2str(Ypos1) '_' num2str(Xpos2) '_' num2str(Ypos2) '.txt'];
        
        if fShowVariable 
            writetable(saveTable,saveFileName,'Delimiter','\t');
        else
            writetable(saveTable,saveFileName,'Delimiter','\t','WriteVariableNames', 0);
        end
    end   
    cd(path)
    
end

%% The end
fclose('all');
clear;