% smm to tif file, a file or all file in a folder //MJ 2121

clear all
%% Filme Info.
	
path = '/Users/brunger/Dropbox/archive/programs/single_molecule/smCamera_conversion/smm_conversion/examples';
AllFileInFolder = 'y';  %'y' all smm file in the folder will be converted
filehead = 'film1';      % for single file 

%% Find smm files
cd(path);
if AllFileInFolder == 'y'
    matfiles = dir(fullfile(path, '*.smm'));
    nfiles = length(matfiles)
else 
    nfiles = 1;
    matfiles(1).name = [filehead '.smm'];
end

%% convert a file or files
for i=1:nfiles
    %% smm file meta info format
%     At the bof (beginning of file), there will be a header of 17 bytes in length.
%     2 byte integer (frame width)
%     2 byte integer (frame height)
%     1 byte integer (byte/pixel)
%     4 byte integer (background value)
%     4 byte integer (data scaler value)
%     4 byte float (frame rate)

    %% Open smm file
    filename = matfiles(i).name
    fid = fopen(filename);
    infoSize = 17; %17 bytes in length.

    %% Read the info.
    sizex = fread(fid, 1, 'uint16');
    sizey = fread(fid, 1, 'uint16');
    pixelByteSize = fread(fid, 1, 'uint8');
    background = fread(fid, 1, 'uint32');
    scaler = fread(fid, 1, 'uint32');
    frameRate = fread(fid, 1, 'float32');

	fprintf('sizex= %d \n',sizex);	
	fprintf('sizey= %d \n',sizey);	
	fprintf('pixelByteSize= %d \n',pixelByteSize);	
	fprintf('background= %d \n',background);	
	fprintf('scaler= %d \n',scaler);	
	fprintf('frameRate= %d \n',frameRate);	

    %% Check the number of frame
    fseek(fid, 0 , 'eof');
    file_size = ftell(fid);
    nframe = fix(file_size-infoSize)/(sizex*sizey*pixelByteSize);
    
    switch pixelByteSize
        case 1 % 8 bit
            smm_image = zeros(sizex,sizey,nframe,'uint8');
            % Read image data
            fseek(fid, infoSize, 'bof');
            temp = fread(fid, sizex*sizey*nframe, 'uint8');
            smm_image(:) = temp;
            % Write the TIF file
            imwrite(smm_image(:,:,1)', [filename(1:end-4) '.tif'], 'tif');
            for fr=2:nframe
                imwrite(smm_image(:,:,fr)', [filename(1:end-4) '.tif'], 'tif', 'WriteMode' ,'append');
            end
        case 2 % 16 bit
            smm_image = zeros(sizex,sizey,nframe,'uint16');
            % Read image data
            fseek(fid, infoSize, 'bof');
            temp = fread(fid, sizex*sizey*nframe, 'uint16');
            smm_image(:) = temp;
            % Write the TIF file
            imwrite(smm_image(:,:,1)', [filename(1:end-4) '.tif'], 'tif');
            for fr=2:nframe
                imwrite(smm_image(:,:,fr)', [filename(1:end-4) '.tif'], 'tif', 'WriteMode' ,'append');
            end
        otherwise
            disp('Not supported data type')
    end
    
end

%% The end
fclose('all');
clear;