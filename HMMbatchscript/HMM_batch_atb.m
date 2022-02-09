% HMM batch processing example by Yunxiang Zhang (yxzhang@gmail.com)
%last updated Nov 12th, 2021

	
	path = '/Users/brunger/Dropbox/archive/programs/single_molecule/HMMbatchscript/examples/film2';

	%% Find smm files
	cd(path);
	matfiles = dir(fullfile(path, '*.txt'));
	nfiles = length(matfiles);
	
	disp(nfiles);

for i=1:nfiles
    filename=matfiles(i).name
    HMMint=Hmmtrace_atb(filename);

txtf1 = figure ('menu','none',...
    'Position', [850 500 450 350],...
    'visible','on',...
    'Resize', 'off');

	set(txtf1,'name','Instructions','numbertitle','off')

	txtFt=uicontrol('Style','text',...
    'Position',[50,240,355,55],...
    'FontSize', 20,...
    'String',['Enter # of steps (0-9), or any other key if uninterpretable.']);

	manual=getkey(1);
	character=char(manual);
	number=str2num(character);
	disp(number);
	
	close all;

    path1=['A',num2str(i)];
    path2=['B',num2str(i)];
    path3=['C',num2str(i)];
	writematrix(number,'film2test.xlsx','Sheet',1,'Range',path1)
	writematrix(filename,'film2test.xlsx','Sheet',1,'Range',path2)
	writematrix(HMMint','film2test.xlsx','Sheet',1,'Range',path3)
end