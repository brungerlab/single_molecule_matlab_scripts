%impoved HMM code for batch processing by Yunxiang Zhang (yxzhang@gmail.com)
%last updated Nov 9th, 2021

function HMMint=Hmmtrace(filename)
%Import the observation sequence
intis=readmatrix(filename);
intis1=intis(:,2)-intis(:,3);%background subtraction-pay attention to definition of each column
intis1(find(isnan(intis1)))=[];%remove NAN entries
%Set the time step
timestep=0.202;

t=length(intis1);%The length of observation sequence


%by default use hierarchical clustering
%use_hcluster=1;
use_hcluster=0;

if use_hcluster==0
    try
        %alternatively if hierarchical clustering does not produce satisfying results
       %% Method 2: Finding the peak position of the histogram of the observation series
        
        %Set peak threshold, number of bins, minimum peak separation, method to determine emission, method to determine dividing line
        
        %Set Minimum peak height; increase to remove spikes;
        PeakThreshold=2;
        %Set number of bins
        Nhist=round(t/25);
        %Set Minimum peak separation
        MinPeakdistance=round(Nhist/10);
        %The emission is determined by median(method=0),peak(method=1), or mean(method=2) value
        method=2;
        %The deviding line is determined by peak width(bmethod=0) or mean value of two neighbouring peaks(bmethod=1)
        bmethod=1;
        
        %Seq:Emission sequence
        %location: Emission intensity
        [seq,intensity]=HMMEmitTrc(intis1,timestep,PeakThreshold,Nhist,MinPeakdistance,method,bmethod);		
    catch
       %% Method 1: Using hierarchical clustering
        X=intis1;
        %Plot the observed data curve
        f=figure;
		f.Position(1:2)=[10 400];
        plot((1:t)*timestep,intis1)
        xlabel('time(s)')
        ylabel('Intensity')
        set(gca,'FontSize',15)
        
        Y=pdist(X,'euclidean');%Compute the pairwise distances
        Z=linkage(Y,'average');%Generate clustering hierarchical tree according to distance information
        %Calculate cophenetic correlation coefficient for the hierarchical cluster tree, a larger value indicates that the tree fits the distance well
        C=cophenet(Z,Y)
        
        
        
        %%%%%%Natural Divisions
        %Set cutoff threshold according from standard deviation and cophenetic correlation coefficient
        %If the number of categories is small,try increasing the cutoff,otherwise reducing the cutoff
        cutoff=10*std(intis1((end-50):end));
        
        %clustering result
        seq = cluster(Z,'cutoff',cutoff,'Criterion','distance');
        seq=seq';
        
        %Determine emission value
        F1=length(unique(seq));
        intensity=zeros(1,F1);
        for i=1:F1
            intensity(i)=mean(intis1(find(seq==i)));
        end
        
        Ctrace=zeros(1,length(intis1));
        for i=1:length(intensity)
            Ctrace(find(seq==i))=intensity(i);
        end
        R=corrcoef(Ctrace,intis1);
        i=0.1;
        while R(1,2)<0.9%increase the correlation threshold to get more clusters
            cutoff=(10-i)*std(intis1((end-50):end));
            i=i+0.1;
            seq = cluster(Z,'cutoff',cutoff,'Criterion','distance');
            seq=seq';
            F1=length(unique(seq));
            intensity=zeros(1,F1);
            for j=1:F1
                intensity(j)=mean(intis1(find(seq==j)));
            end
            for j=1:F1
                Ctrace(find(seq==j))=intensity(j);
            end
            R=corrcoef(Ctrace,intis1);
        end
    end
else
       %% Method 1: Using hierarchical clustering
        X=intis1;
        %Plot the observed data curve
        figure
        plot((1:t)*timestep,intis1)
        xlabel('time(s)')
        ylabel('Intensity')
        set(gca,'FontSize',15)
        
        Y=pdist(X,'euclidean');%Compute the pairwise distances
        Z=linkage(Y,'average');%Generate clustering hierarchical tree according to distance information
        %Calculate cophenetic correlation coefficient for the hierarchical cluster tree, a larger value indicates that the tree fits the distance well
        C=cophenet(Z,Y)
        
        %%%%%%Natural Divisions
        %Set cutoff threshold according from standard deviation and cophenetic correlation coefficient
        %If the number of categories is small,try increasing the cutoff,otherwise reducing the cutoff
        cutoff=10*std(intis1((end-50):end));
        
        %clustering result
        seq = cluster(Z,'cutoff',cutoff,'Criterion','distance');
        seq=seq';
        
        %Determine emission value
        F1=length(unique(seq));
        intensity=zeros(1,F1);
        for i=1:F1
            intensity(i)=mean(intis1(find(seq==i)));
        end
        
        Ctrace=zeros(1,length(intis1));
        for i=1:length(intensity)
            Ctrace(find(seq==i))=intensity(i);
        end
        R=corrcoef(Ctrace,intis1);
        i=0.1;
        while R(1,2)<0.95%increase the correlation threshold to get more clusters
            cutoff=(10-i)*std(intis1((end-50):end));
            i=i+0.1;
            seq = cluster(Z,'cutoff',cutoff,'Criterion','distance');
            seq=seq';
            F1=length(unique(seq));
            intensity=zeros(1,F1);
            for j=1:F1
                intensity(j)=mean(intis1(find(seq==j)));
            end
            for j=1:F1
                Ctrace(find(seq==j))=intensity(j);
            end
            R=corrcoef(Ctrace,intis1);
        end
end
%% 
%%%%%% Baum-welch algorithm is used to estimate the transfer probability, emission probability 
lloc=length(intensity);
TRANS_GUESS = eye(lloc)*0.9+rand(lloc,lloc)*0.1;
EMIS_GUESS = eye(lloc)*0.9+rand(lloc,lloc)*0.1;
[TRANS_EST2, EMIS_EST2] = hmmtrain(seq, TRANS_GUESS, EMIS_GUESS);

%%%%%% The state sequence is estimated by Viterbi algorithm
likelystates = hmmviterbi(seq, TRANS_EST2, EMIS_EST2);

%Draw analysis results
hold on
likest=likelystates ;
for i=1:length(intensity)
likest(find(likelystates==i))=intensity(i);
end
plot((1:t)*timestep,likest);
disp(['The number of state is ',num2str(length(intensity))])
disp(['The probability transition matrix is',newline])
disp(num2str(TRANS_EST2))

Hint=likelystates;
for i=length(intensity):(-1):1
Hint(find(Hint==i))=intensity(i);
end

filenamewt=filename(1:(end-4));
filepng=[filenamewt,'.png'];
saveas(gca,filepng)
	

HMMint=Hint';%State sequence
end
