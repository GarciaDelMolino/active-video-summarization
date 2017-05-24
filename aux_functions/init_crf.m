addpath(genpath('aux_functions')) 
%% kmeans for question inference
[ ~, c,distC] = myk_means( desc_seg, 20 , [] );
segments=arrayfun(@(i) find(c==i),1:20,'UniformOutput',0);
[~,lo]=cellfun(@(i) sort(distC(i)),segments,'UniformOutput',0);
segments(2,:)=cellfun(@(i) distC(i),cellfun(@(i,j) j(i),lo,segments,'UniformOutput',0),'UniformOutput',0);
segments(:,(cellfun(@(i) isempty(i), segments(1,:))))=[];

clear c distC lo

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                         parameters crf                                %%         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d=triu(pdist2(desc_seg,desc_seg));

%compute value for cij, cji:
if param.cij==100
    param.cij=max(d(d>0));
elseif param.cij==50
    param.cij=median(d(d>0));
else
    param.cij=prctile(d(d>0),param.cij);
end

if param.cji==100
    param.cji=max(d(d>0));
elseif param.cji==50
    param.cji=median(d(d>0));
else
    param.cji=prctile(d(d>0),param.cji);
end

d=d.*(~diag(ones(length(d)-1,1),1))+min(0.01,param.cji/100)*diag(ones(length(d)-1,1),1);
doff=min(min(d>min(0.01,param.cji/100)));


if (param.config==5)   %  -e^(-dk) [l*p 1 1 -l*p/5]
    [cnn(:,1), cnn(:,2)]=find((d<param.cji)&(d~=0));
    cnn=cnn(cnn(:,1)<cnn(:,2),:)';
    [far(:,1), far(:,2)]=find(d>param.cij);
    far=far(far(:,1)<far(:,2),:)';
    cnn=[cnn,far];  
    cnnd=exp(max(min(0.01,param.cji/100),d(cnn(1,:)+(cnn(2,:)-1)*size(d,1))-doff)*(-param.kji)); 
    cnnp=-[param.pji; 1; 1; -(param.pji/5)];
    cnn(3:6,:)=cnnp*cnnd;
end

clear doff
