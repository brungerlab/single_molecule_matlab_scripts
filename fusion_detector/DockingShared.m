%This script will make a "Matched" variable, which contains both the name
%of the docking event from red (aka channel 2/right) channel and the time of
%fusion from the green (aka channel 1/left) channel.
Matched={}
MatchedTime=[]
for i=1:length(confirmedHits2);
    idx=find(strcmp({confirmedHits.name}, confirmedHits2(i).name)==1);
    if length(idx)>0;
        for j=1:length(idx);
        Matched=[Matched;confirmedHits2(i).name];
        Time=confirmedHits2(i).time-confirmedHits(idx(j)).time;
        MatchedTime=[MatchedTime;Time];
        end
    end
end

for i=1:length(Matched);
    Matched{i,2}=MatchedTime(i);
end
