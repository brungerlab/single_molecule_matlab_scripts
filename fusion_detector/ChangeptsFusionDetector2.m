for i=1:length(dataName);
[ExMean, ExMeanResid]=findchangepts(chan2Baseline(:,i),'statistic','mean','maxNumChanges',3);
[ExRMS, ExRMSResid]=findchangepts(chan2Baseline(:,i),'statistic','rms','maxNumChanges',3);
[ExSTD, ExSTDResid]=findchangepts(chan2Baseline(:,i),'statistic','std','maxNumChanges',3);

if length(ExMean)>0;
    Test2(i).ExMean=ExMean;
    Test2(i).ExMeanResid=ExMeanResid;
else
    Test2(i).ExMean=0;
    Test2(i).ExMeanResid=0;
end
if length(ExRMS)>0;
    Test2(i).ExRMS=ExRMS;
    Test2(i).ExRMSResid=ExRMSResid;
else
    Test2(i).ExRMS=0;
    Test2(i).ExRMSResid=0;
end
if length(ExSTD)>0;
    Test2(i).ExSTD=ExSTD;
    Test2(i).ExSTDResid=ExSTDResid;
else
    Test2(i).ExSTD=0;
    Test2(i).ExSTDResid=0;
end
end
% This part calculates a Mean=mean(hit position:hit pos.+20)-mean(hit pos-21:hit pos-1)
% a MiniMean=mean(hit pos:hit pos +10)-mean(hit pos-11:hit pos -1)
% a Standard Deviation = Std(hit pos-21:hitpos-1)
%%
for i=1:length(Test2);
    for j=1:length(Test2(i).ExMean);    
        if Test2(i).ExMean(j)>0 && Test2(i).ExMean(j)+20<size(chan1Background,1) && Test2(i).ExMean(j)-21 > 0;
            Test2(i).Mean(j)=mean(chan1Baseline(Test2(i).ExMean(j):Test2(i).ExMean(j)+20,i))-mean(chan1Baseline(Test2(i).ExMean(j)-21:Test2(i).ExMean(j)-1,i));
            Test2(i).MiniMean(j)=mean(chan1Baseline(Test2(i).ExMean(j):Test2(i).ExMean(j)+10,1))-mean(chan1Baseline(Test2(i).ExMean(j)-11:Test2(i).ExMean(j)-1,i));
            Test2(i).Std(j)=std(chan1Baseline(Test2(i).ExMean(j)-21:Test2(i).ExMean(j)-1,i));
        else
            Test2(i).Mean(j)=0;
            Test2(i).MiniMean(j)=0;
            Test2(i).Std(j)=0;
        end
    end
end
%%
%If Any two of ExMean, ExRMS, or ExSTD are greater than 0 AND the Mean is greater than zero then true
%Need to match indices
for i=1:length(Test2)
    for j=1:length(Test2(i).Mean);
        [k]=find(Test2(i).ExRMS>Test2(i).ExMean(j)-5 & Test2(i).ExRMS<Test2(i).ExMean(j)+5);
        [l]=find(Test2(i).ExSTD>Test2(i).ExMean(j)-5 & Test2(i).ExSTD<Test2(i).ExMean(j)+5);
        if length(k)>2;
            [mink Kindex]=min(abs(Test2(i).ExMean(j)-Test2(i).ExRMS));
        elseif length(k)>1;
            Kindex=min(k);
        else
            Kindex=k;
        end
               
        if length(l)>2;
            [minl Lindex]=min(abs(Test2(i).ExMean(j)-Test2(i).ExSTD));
        elseif length(l)>1;
            Lindex=min(l);
        else
            Lindex=l;
        end       
        
        if length(Kindex)>0 && length(Lindex)>0
            if Test2(i).ExMean(j)>0 && Test2(i).ExRMS(Kindex)>0 && Test2(i).Mean(j)>0 || Test2(i).ExMean(j)>0 && Test2(i).ExSTD(Lindex)>0 && Test2(i).Mean(j)>0 || Test2(i).ExRMS(Kindex)>0 && Test2(i).ExSTD(Lindex)>0 && Test2(i).Mean(j)>0;
                Test2(i).PosMean(j)=1;
            else
                Test2(i).PosMean(j)=0;
            end
        else
            Test2(i).PosMean(j)=0;
        end
    end
    Test2(i).PutativeTrue=[];
end
            

%%
%Is the hit also in the putative Hits? And if so, the time index of the
%putative hit
for i=1:length(putativeHits2);
    Test2(putativeHits2(i).datasetIndex).PutativeTrue=[Test2(putativeHits2(i).datasetIndex).PutativeTrue, putativeHits2(i).timeIndex];
end
for i=1:length(Test2)
    if Test2(i).PutativeTrue>0
        Test2(i).PutativeTrue = Test2(i).PutativeTrue;
    else
        Test2(i).PutativeTrue=[];
    end
end
%conformation only
%for i=1:length(confirmedHits);
 %   Test2(confirmedHits(i).datasetIndex).confirmedHits=1;
%end
%for i=1:length(Test2)
%    if Test2(i).confirmedHits>0
%        Test2(i).confirmedHits = Test2(i).confirmedHits;
%    else
%        Test2(i).confirmedHits=0;
%    end
%end

% Test2 to see if the mean was greater than 1.4 times the STD
%for i=1:length(Test2);
%    for j=1:length(Test2(i).Mean);
%    if Test2(i).PosMean(j)>0;
%        if max(Test2(i).Mean(j), Test2(i).MiniMean(j))>Test2(i).Std(j)*1.4 
%            Test2(i).IsHit(j)=1;
%            Test2(i).Index(j)=Test2(i).ExMean(j);
%        else
%           Test2(i).IsHit(j)=0;
%            Test2(i).Index(j)=0;
%        end
%    else
%        Test2(i).IsHit(j)=0;
%        Test2(i).Index(j)=0;
%    end
%    end
%end
%%
%This checks that the automated hit existed in the putative hits and was
%reasonably close (+/- 10 frames) to the putative hit time
for i=1:length(Test2);
    if length(Test2(i).PutativeTrue>0)>0;
        for j=1:length(Test2(i).PutativeTrue);
            if isempty(find(Test2(i).ExMean>Test2(i).PutativeTrue(j)-10 & Test2(i).ExMean<Test2(i).PutativeTrue(j)+10));
                Test2(i).Confirmed(j,1)=0;
            elseif length(find(Test2(i).ExMean>Test2(i).PutativeTrue(j)-10 & Test2(i).ExMean<Test2(i).PutativeTrue(j)+10))<2;
                Test2(i).Confirmed(j,1)=find(Test2(i).ExMean>Test2(i).PutativeTrue(j)-10 & Test2(i).ExMean<Test2(i).PutativeTrue(j)+10);
            elseif length(find(Test2(i).ExMean>Test2(i).PutativeTrue(j)-10 & Test2(i).ExMean<Test2(i).PutativeTrue(j)+10))>1;
                [m mmeanindex]=min(abs(Test2(i).ExMean-Test2(i).PutativeTrue(j)));
                Test2(i).Confirmed(j,1)=find(Test2(i).ExMean(mmeanindex)>Test2(i).PutativeTrue(j)-10 & Test2(i).ExMean(mmeanindex)<Test2(i).PutativeTrue(j)+10);
            elseif Test2(i).ExMean==0
                Test2(i).Confirmed(j,1)=0;
            end
            
            if isempty(find(Test2(i).ExRMS>Test2(i).PutativeTrue(j)-10 & Test2(i).ExRMS<Test2(i).PutativeTrue(j)+10));
                Test2(i).Confirmed(j,2)=0;
            elseif length(find(Test2(i).ExRMS>Test2(i).PutativeTrue(j)-10 & Test2(i).ExRMS<Test2(i).PutativeTrue(j)+10))<2;
                Test2(i).Confirmed(j,2)=find(Test2(i).ExRMS>Test2(i).PutativeTrue(j)-10 & Test2(i).ExRMS<Test2(i).PutativeTrue(j)+10);
            elseif length(find(Test2(i).ExRMS>Test2(i).PutativeTrue(j)-10 & Test2(i).ExRMS<Test2(i).PutativeTrue(j)+10))>1;
                [m mExRMSindex]=min(abs(Test2(i).ExRMS-Test2(i).PutativeTrue(j)));
                Test2(i).Confirmed(j,2)=find(Test2(i).ExRMS(mExRMSindex)>Test2(i).PutativeTrue(j)-10 & Test2(i).ExRMS(mExRMSindex)<Test2(i).PutativeTrue(j)+10);
            elseif Test2(i).ExRMS==0
                Test2(i).Confirmed(j,2)=0;
            end
            
            if isempty(find(Test2(i).ExSTD>Test2(i).PutativeTrue(j)-10 & Test2(i).ExSTD<Test2(i).PutativeTrue(j)+10));
                Test2(i).Confirmed(j,3)=0;
            elseif length(find(Test2(i).ExSTD>Test2(i).PutativeTrue(j)-10 & Test2(i).ExSTD<Test2(i).PutativeTrue(j)+10))<2;
                Test2(i).Confirmed(j,3)=find(Test2(i).ExSTD>Test2(i).PutativeTrue(j)-10 & Test2(i).ExSTD<Test2(i).PutativeTrue(j)+10);
            elseif length(find(Test2(i).ExSTD>Test2(i).PutativeTrue(j)-10 & Test2(i).ExSTD<Test2(i).PutativeTrue(j)+10))>1;
                [m mExSTDindex]=min(abs(Test2(i).ExSTD-Test2(i).PutativeTrue(j)));
                Test2(i).Confirmed(j,3)=find(Test2(i).ExSTD(mExSTDindex)>Test2(i).PutativeTrue(j)-10 & Test2(i).ExSTD(mExSTDindex)<Test2(i).PutativeTrue(j)+10);
            elseif Test2(i).ExSTD==0;
                Test2(i).Confirmed(j,3)=0;
            end
            
            if sum(Test2(i).Confirmed(j,:)>0)>=2
                Test2(i).Yeppers(j)=Test2(i).PutativeTrue(j);
            end
        end
    else
        Test2(i).Confirmed=0;
    end
end
%%

%Adds a validated column to the putativeHits2 structure
for i=1:length(putativeHits2);
    if length(Test2(putativeHits2(i).datasetIndex).Yeppers)==1 && Test2(putativeHits2(i).datasetIndex).Yeppers==putativeHits2(i).timeIndex;
        putativeHits2(i).Validated=1;
    elseif length(Test2(putativeHits2(i).datasetIndex).Yeppers)>1 
        for yip=1:length(Test2(putativeHits2(i).datasetIndex).Yeppers)
            if Test2(putativeHits2(i).datasetIndex).Yeppers(yip)==putativeHits2(i).timeIndex;
                putativeHits2(i).Validated=1;
                break
            else
                putativeHits2(i).Validated=0;
            end
        end
    else
        putativeHits2(i).Validated=0;
    end
    if i > 1;
        if putativeHits2(i).datasetIndex == putativeHits2(i-1).datasetIndex && (putativeHits2(i).timeIndex - putativeHits2(i-1).timeIndex)<15
            putativeHits2(i).Validated=0;        
        end
    end
end