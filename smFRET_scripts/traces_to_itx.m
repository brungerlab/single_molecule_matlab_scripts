
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% analyzes docking time traces of tir                                                                  %
%     runs through all .traces files in a folder                                                                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function brandon_folder_view_tir;
prompstr={'path (dont end in \) to folder with .traces:','Enter prefix of file being analyzed (rib):','Enter # for first movie','Enter # for last movie'};
initstr={'C:\keith\analysis\','smt','1','10'};
titlestr='DO NOT PRESS CANCEL!';
nlines=1;
result=inputdlg(prompstr,titlestr,nlines,initstr);

Initialdir = result{1};
fileprefix= result{2};
startNum = str2num(result{3});
endNum = str2num(result{4});

dir=[Initialdir '/'];
display (dir)
cd(dir);
close all;
    counter = 0  

keithswitch = 1

for j = startNum :endNum ,								%iterate on the movie number
close all;
   counter = 0   %reset counter each movie if want to
file = [fileprefix num2str(j) ];   
to_open = strcat(file,'.traces');
fid=fopen(to_open,'r');
disp('working on');
disp(file);
len=fread(fid,1,'int32');
disp('The length of the time traces is: ')
disp(len)
Ntraces=fread(fid,1,'int16')
disp('The number of molceules is:')
disp(Ntraces/2);
raw=fread(fid,Ntraces*len,'int16');
disp('Done reading data.');
index=(1:Ntraces*len);
time1 = zeros(1,len);
Data=zeros(Ntraces+1,len);
donor=zeros(Ntraces/2,len);
acceptor=zeros(Ntraces/2,len);
fretE=zeros(Ntraces/2,len);
time_1 = zeros(len,1);
donor_1 = zeros(len,Ntraces/2);
acceptor_1 = zeros(len,Ntraces/2);
time=(0:(len-1));
Data(index)=raw(index);
time1(1,:) = Data(1,:);

for i=1:(Ntraces/2),
   donor(i,:)=Data(i*2,:); %bug found 112106
   acceptor(i,:)=Data(i*2+1,:);  %bug found 112106
   %acceptor(i,:)=Data(i*2,:);
   %donor(i,:)=Data(i*2+1,:);
end

axis_x = len*1;	%for time lapse need to multiply by spacing (usu 350)--for regular *1
m1=1;
%m1 = input('number of starting trace = ');
%leakage = 0.00;			%for cy3 leakage into cy5 factor 0.09, set to zero for calcein/cy5
leakage = 0.09;   %41708 subtract bg in matlab %121307 BR 
AnotherPrevLastGood=m1
prevlastgood=m1	%to allow user to go back 2 traces
lastgood=m1			%to allow user to go back 2 traces
m=m1

while m < (Ntraces/2 + 1)
   
   time_1 = time1';
   donor_1 = donor(m,:)';
   acceptor_1 = acceptor(m,:)'-leakage*donor_1;	%9% leakage Cy3 into Cy5 
   cy5max=-10000
   for i = 1:len
      if acceptor_1(i,1)>cy5max
         cy5max = acceptor_1(i,1);
      end
      total = donor_1(i,1)+acceptor_1(i,1);
      if total <= 0
         fret_1(i,1) = 0.01;
      else
         fret_1(i,1) = acceptor_1(i,1)/(donor_1(i,1)+acceptor_1(i,1));
      end
   end
    
   cy3BLsum=0;
   cy5BLsum=0;
   for d = 5:9
   	cy5BLsum=cy5BLsum+acceptor_1(d,1);
    cy3BLsum=cy3BLsum+donor_1(d,1);
   end
   cy3BLsum = cy3BLsum / 5;
   cy5BLsum = cy5BLsum / 5;
 
   cy3GRsum=0;
   cy5GRsum=0;
   for d = 21:25
   	cy5GRsum=cy5GRsum+acceptor_1(d,1);
      cy3GRsum=cy3GRsum+donor_1(d,1);
   end
   cy3GRsum = cy3GRsum / 5;
   cy5GRsum = cy5GRsum / 5;
   
   cy3RedLatesum=0;
   cy5RedLatesum=0;
   %for d = 15:17
 %  for d = 405:407
 %     cy5RedLatesum=cy5RedLatesum+acceptor_1(d,1);
 %     cy3RedLatesum=cy3RedLatesum+donor_1(d,1);
 %  end
%  cy3RedLatesum= cy3RedLatesum/ 3;
 %  cy5RedLatesum= cy5RedLatesum/ 3;
   
 %if cy5BLsum < 180 & cy5GRsum < 500
 % if cy5BLsum < 1500   & cy3GRsum < 1300 
 if keithswitch > 0		%show all traces  
      counter = counter +1
   subplot (2,1,1)
   plot(time_1(1:len-5),donor_1(1:len-5),'b',time_1(1:len-5),acceptor_1(1:len-5),'r');
   %plot(time_1(1:len-5),donor_1(1:len-5),'r');	%plot donor only
   %plot(time_1(1:len-5),acceptor_1(1:len-5),'r'); %acceptor only
	grid on;
   temp=axis;
   temp(1)=0;
   temp(2)=axis_x;
   axis(temp);
   title(['Molecule ' num2str(m) ' ' file]);
   zoom on;
   subplot (2,1,2)
   plot(time_1(1:len-5),fret_1(1:len-5),'m');
   grid on;
   axis([0 axis_x -0.1 1.1])
   zoom on;

   ans = input('press k to smooth and press others to pass--->b to back up a trace === ','s');
   if isempty(ans)== 1
      ans=' '
      AnotherPrevLastGood=prevlastgood;
      prevlastgood=lastgood;
      lastgood = m;
      m=m+1;   
   end
   
   if ans== 'b'
      m=lastgood-1;
   	lastgood=prevlastgood;   
   	prevlastgood=AnotherPrevLastGood;   
   end
   

   if ans == 'k'
      A = 'q';
      while (strcmp(A,'k')==0)
         
      donor_bg = 0;
      acceptor_bg = 0;
      donor_1 = donor(m,:)'-donor_bg;
      acceptor_1 = acceptor(m,:)'-acceptor_bg-leakage*donor_1;
      for i = 1:len
         total = donor_1(i,1)+acceptor_1(i,1);
         if total <= 0
            fret_1(i,1) = 0.01;
         else
            fret_1(i,1) = acceptor_1(i,1)/(donor_1(i,1)+acceptor_1(i,1));
         end
      end
      
        % smooth the data with n points average
        % n = input('n of points to average over = '); %modified 70607 dom
         n=1; %modified 70607 dom
         len_n = floor((len-5)/n);

			time_n = zeros(len_n,1);
			donor_n = zeros(len_n,1);
			acceptor_n = zeros(len_n,1);
			fret_n = zeros(len_n,1);

         for i = 1:len_n
            time_n(i,1) = sum(time_1(n*i-n+1:n*i,1))/n;
   			donor_n(i,1) = sum(donor_1(n*i-n+1:n*i,1))/n;
   			acceptor_n(i,1) = sum(acceptor_1(n*i-n+1:n*i,1))/n;
            total_n = donor_n(i,1)+acceptor_n(i,1);
            if total_n<=0
               fret_n(i,1) = 0.01;
            else
               fret_n(i,1) = acceptor_n(i,1)/(donor_n(i,1)+acceptor_n(i,1));
            end
            
         end

			subplot (2,1,1);
			plot(time_n,donor_n,'b',time_n,acceptor_n,'r');
         zoom on;
         temp=axis;
         temp(1)=0;
         temp(2)=axis_x;
         axis(temp);
			title (num2str(m));
			grid on;
			subplot (2,1,2);
			plot(time_n,fret_n,'m');
			zoom on;
         axis([0 axis_x -0.1 1.1]);
         grid on;
         
         %A = input('satisfied with the smoothed trace? k = ok, others = not','s'); 
         A='k';  %70607
      end
      
     % ans = input ('to save the trace press k === ','s'); %70607
     ans='k'; %70607
         if isempty(ans)== 1
      		ans=' '
            AnotherPrevLastGood=prevlastgood;
            prevlastgood=lastgood;
     			lastgood = m;
   			m = m+1;   
 			  end

      if ans == 'k'
         fname=[file 'trace' num2str(m) '.itx'];
         igorname=[file 'trace' num2str(m)];
         [fid2,message] = fopen(fname,'w');
			fprintf(fid2,'IGOR\nWAVES/D ');		%also calculate delta R Squared for 1 step
         fprintf(fid2,'donor');
         fprintf(fid2,igorname);	
			fprintf(fid2,'	acceptor');		
         fprintf(fid2,igorname);
       	fprintf(fid2,'\n');		
			fprintf(fid2,'BEGIN\n');

for i = 1:len
   fprintf(fid2, num2str(donor_1(i,1)));
   fprintf(fid2, '	');
   fprintf(fid2, num2str(acceptor_1(i,1)));
   fprintf(fid2, '\n');
end

         fprintf(fid2,'\nEND\n');         
         fclose(fid2);         
         AnotherPrevLastGood=prevlastgood;     
         prevlastgood=lastgood;
      	lastgood = m;
         m=m+1   
      end
               
   end
else
     m=m+1
end   
end
display(counter);
end % end iterate on movie number in a give folder



