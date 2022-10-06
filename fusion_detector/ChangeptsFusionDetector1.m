
for i=1:length(dataName);
[ExMean, ExMeanResid]=findchangepts(chan1Baseline(:,i),'statistic','mean','maxNumChanges',3);
[ExRMS, ExRMSResid]=findchangepts(chan1Baseline(:,i),'statistic','rms','maxNumChanges',3);
[ExSTD, ExSTDResid]=findchangepts(chan1Baseline(:,i),'statistic','std','maxNumChanges',3);

if length(ExMean)>0;
    Test1(i).ExMean=ExMean;
    Test1(i).ExMeanResid=ExMeanResid;
else
    Test1(i).ExMean=0;
    Test1(i).ExMeanResid=0;
end
if length(ExRMS)>0;
    Test1(i).ExRMS=ExRMS;
    Test1(i).ExRMSResid=ExRMSResid;
else
    Test1(i).ExRMS=0;
    Test1(i).ExRMSResid=0;
end
if length(ExSTD)>0;
    Test1(i).ExSTD=ExSTD;
    Test1(i).ExSTDResid=ExSTDResid;
else
    Test1(i).ExSTD=0;
    Test1(i).ExSTDResid=0;
end
end
% This part calculates a Mean=mean(hit position:hit pos.+20)-mean(hit pos-21:hit pos-1)
% a MiniMean=mean(hit pos:hit pos +10)-mean(hit pos-11:hit pos -1)
% a Standard Deviation = Std(hit pos-21:hitpos-1)
%%
for i=1:length(Test1);
    for j=1:length(Test1(i).ExMean);    
        if Test1(i).ExMean(j)>0 && Test1(i).ExMean(j)+20<size(chan1Background,1) && Test1(i).ExMean(j)-21 > 0;
            Test1(i).Mean(j)=mean(chan1Baseline(Test1(i).ExMean(j):Test1(i).ExMean(j)+20,i))-mean(chan1Baseline(Test1(i).ExMean(j)-21:Test1(i).ExMean(j)-1,i));
            Test1(i).MiniMean(j)=mean(chan1Baseline(Test1(i).ExMean(j):Test1(i).ExMean(j)+10,1))-mean(chan1Baseline(Test1(i).ExMean(j)-11:Test1(i).ExMean(j)-1,i));
            Test1(i).Std(j)=std(chan1Baseline(Test1(i).ExMean(j)-21:Test1(i).ExMean(j)-1,i));
        else
            Test1(i).Mean(j)=0;
            Test1(i).MiniMean(j)=0;
            Test1(i).Std(j)=0;
        end
    end
end
%%
%If Any two of ExMean, ExRMS, or ExSTD are greater than 0 AND the Mean is greater than zero then true
%Need to match indices
for i=1:length(Test1)
    for j=1:length(Test1(i).Mean);
        [k]=find(Test1(i).ExRMS>Test1(i).ExMean(j)-5 & Test1(i).ExRMS<Test1(i).ExMean(j)+5);
        [l]=find(Test1(i).ExSTD>Test1(i).ExMean(j)-5 & Test1(i).ExSTD<Test1(i).ExMean(j)+5);
        if length(k)>2;
            [mink Kindex]=min(abs(Test1(i).ExMean(j)-Test1(i).ExRMS));
        elseif length(k)>1;
            Kindex=min(k);
        else
            Kindex=k;
        end
               
        if length(l)>2;
            [minl Lindex]=min(abs(Test1(i).ExMean(j)-Test1(i).ExSTD));
        elseif length(l)>1;
            Lindex=min(l);
        else
            Lindex=l;
        end       
        
        if length(Kindex)>0 && length(Lindex)>0
            if Test1(i).ExMean(j)>0 && Test1(i).ExRMS(Kindex)>0 && Test1(i).Mean(j)>0 || Test1(i).ExMean(j)>0 && Test1(i).ExSTD(Lindex)>0 && Test1(i).Mean(j)>0 || Test1(i).ExRMS(Kindex)>0 && Test1(i).ExSTD(Lindex)>0 && Test1(i).Mean(j)>0;
                Test1(i).PosMean(j)=1;
            else
                Test1(i).PosMean(j)=0;
            end
        else
            Test1(i).PosMean(j)=0;
        end
    end
    Test1(i).PutativeTrue=[];
end
            

%%
%Is the hit also in the putative Hits? And if so, the time index of the
%putative hit
for i=1:length(putativeHits);
    Test1(putativeHits(i).datasetIndex).PutativeTrue=[Test1(putativeHits(i).datasetIndex).PutativeTrue, putativeHits(i).timeIndex];
end
for i=1:length(Test1)
    if Test1(i).PutativeTrue>0
        Test1(i).PutativeTrue = Test1(i).PutativeTrue;
    else
        Test1(i).PutativeTrue=[];
    end
end
%conformation only
%for i=1:length(confirmedHits);
 %   Test1(confirmedHits(i).datasetIndex).confirmedHits=1;
%end
%for i=1:length(Test1)
%    if Test1(i).confirmedHits>0
%        Test1(i).confirmedHits = Test1(i).confirmedHits;
%    else
%        Test1(i).confirmedHits=0;
%    end
%end

% Test1 to see if the mean was greater than 1.4 times the STD
%for i=1:length(Test1);
 %   for j=1:length(Test1(i).Mean);
%    if Test1(i).PosMean(j)>0;
%        if max(Test1(i).Mean(j), Test1(i).MiniMean(j))>Test1(i).Std(j)*1.4 
%            Test1(i).IsHit(j)=1;
%            Test1(i).Index(j)=Test1(i).ExMean(j);
%        else
%            Test1(i).IsHit(j)=0;
%            Test1(i).Index(j)=0;
%        end
%    else
%        Test1(i).IsHit(j)=0;
%        Test1(i).Index(j)=0;
    %end
   % end
%end
%%
%This checks that the automated hit existed in the putative hits and was
%reasonably close (+/- 10 frames) to the putative hit time
for i=1:length(Test1);
    if length(Test1(i).PutativeTrue>0)>0;
        for j=1:length(Test1(i).PutativeTrue);
            if isempty(find(Test1(i).ExMean>Test1(i).PutativeTrue(j)-10 & Test1(i).ExMean<Test1(i).PutativeTrue(j)+10));
                Test1(i).Confirmed(j,1)=0;
            elseif length(find(Test1(i).ExMean>Test1(i).PutativeTrue(j)-10 & Test1(i).ExMean<Test1(i).PutativeTrue(j)+10))<2;
                Test1(i).Confirmed(j,1)=find(Test1(i).ExMean>Test1(i).PutativeTrue(j)-10 & Test1(i).ExMean<Test1(i).PutativeTrue(j)+10);
            elseif length(find(Test1(i).ExMean>Test1(i).PutativeTrue(j)-10 & Test1(i).ExMean<Test1(i).PutativeTrue(j)+10))>1;
                [m mmeanindex]=min(abs(Test1(i).ExMean-Test1(i).PutativeTrue(j)));
                Test1(i).Confirmed(j,1)=find(Test1(i).ExMean(mmeanindex)>Test1(i).PutativeTrue(j)-10 & Test1(i).ExMean(mmeanindex)<Test1(i).PutativeTrue(j)+10);
            elseif Test1(i).ExMean==0
                Test1(i).Confirmed(j,1)=0;
            end
            
            if isempty(find(Test1(i).ExRMS>Test1(i).PutativeTrue(j)-10 & Test1(i).ExRMS<Test1(i).PutativeTrue(j)+10));
                Test1(i).Confirmed(j,2)=0;
            elseif length(find(Test1(i).ExRMS>Test1(i).PutativeTrue(j)-10 & Test1(i).ExRMS<Test1(i).PutativeTrue(j)+10))<2;
                Test1(i).Confirmed(j,2)=find(Test1(i).ExRMS>Test1(i).PutativeTrue(j)-10 & Test1(i).ExRMS<Test1(i).PutativeTrue(j)+10);
            elseif length(find(Test1(i).ExRMS>Test1(i).PutativeTrue(j)-10 & Test1(i).ExRMS<Test1(i).PutativeTrue(j)+10))>1;
                [m mExRMSindex]=min(abs(Test1(i).ExRMS-Test1(i).PutativeTrue(j)));
                Test1(i).Confirmed(j,2)=find(Test1(i).ExRMS(mExRMSindex)>Test1(i).PutativeTrue(j)-10 & Test1(i).ExRMS(mExRMSindex)<Test1(i).PutativeTrue(j)+10);
            elseif Test1(i).ExRMS==0
                Test1(i).Confirmed(j,2)=0;
            end
            
            if isempty(find(Test1(i).ExSTD>Test1(i).PutativeTrue(j)-10 & Test1(i).ExSTD<Test1(i).PutativeTrue(j)+10));
                Test1(i).Confirmed(j,3)=0;
            elseif length(find(Test1(i).ExSTD>Test1(i).PutativeTrue(j)-10 & Test1(i).ExSTD<Test1(i).PutativeTrue(j)+10))<2;
                Test1(i).Confirmed(j,3)=find(Test1(i).ExSTD>Test1(i).PutativeTrue(j)-10 & Test1(i).ExSTD<Test1(i).PutativeTrue(j)+10);
            elseif length(find(Test1(i).ExSTD>Test1(i).PutativeTrue(j)-10 & Test1(i).ExSTD<Test1(i).PutativeTrue(j)+10))>1;
                [m mExSTDindex]=min(abs(Test1(i).ExSTD-Test1(i).PutativeTrue(j)));
                Test1(i).Confirmed(j,3)=find(Test1(i).ExSTD(mExSTDindex)>Test1(i).PutativeTrue(j)-10 & Test1(i).ExSTD(mExSTDindex)<Test1(i).PutativeTrue(j)+10);
            elseif Test1(i).ExSTD==0;
                Test1(i).Confirmed(j,3)=0;
            end
            
            if sum(Test1(i).Confirmed(j,:)>0)>=2
                Test1(i).Yeppers(j)=Test1(i).PutativeTrue(j);
            end
        end
    else
        Test1(i).Confirmed=0;
    end
end
%%

%Adds a validated column to the putativeHits structure
for i=1:length(putativeHits);
    if length(Test1(putativeHits(i).datasetIndex).Yeppers)==1 && Test1(putativeHits(i).datasetIndex).Yeppers==putativeHits(i).timeIndex;
        putativeHits(i).Validated=1;
    elseif length(Test1(putativeHits(i).datasetIndex).Yeppers)>1 
        for yip=1:length(Test1(putativeHits(i).datasetIndex).Yeppers)
            if Test1(putativeHits(i).datasetIndex).Yeppers(yip)==putativeHits(i).timeIndex;
                putativeHits(i).Validated=1;
                break
            else
                putativeHits(i).Validated=0;
            end
        end
    else
        putativeHits(i).Validated=0;
    end
    if i > 1;
        if putativeHits(i).datasetIndex == putativeHits(i-1).datasetIndex && (putativeHits(i).timeIndex - putativeHits(i-1).timeIndex)<15
            putativeHits(i).Validated=0;        
        end
    end
end