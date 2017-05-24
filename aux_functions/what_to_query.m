%[improv, dif, p, probs]=what_to_query(summ, prob0, node, cnn0, param0, user0,d, a,prefs,prune,lcl)
addpath(genpath(code_mrf))    
addpath(genpath('aux_functions')) 

prob0=prob;
cnn0=cnn;
param0=param;
if exist('qs','var')
    a=qs;
else
    a=find(summ==1)';
end

N=4;
improv=cell(length(a)*N,1);%[yy yn ny nn y- n-] N times (for each selected node (a))
probs=cell(length(a)*N,1);
params=cell(length(a)*N,1);
%odds too low:
skip=prob_q<0.01*max(max(prob_q));
%already answered (should be empty, but just in case):
skip=skip+repmat(logical(ismember(a, [user.want user.no_want])'),[1,N]); 

user0=user;

user=cell(length(a),N);
[user{:,:}]=deal(user0);
for i=1:length(a)  
    user{i,1}.want=[user{i,1}.want, a(i)];
    user{i,2}.want=[user{i,2}.want, a(i)];        
    user{i,1}.bring_w=[user{i,1}.bring_w, {1}];
    user{i,2}.bring_w=[user{i,2}.bring_w, {0}];

    user{i,3}.no_want=[user{i,3}.no_want, a(i)];
    user{i,4}.no_want=[user{i,4}.no_want, a(i)];             
    user{i,3}.bring_nw=[user{i,3}.bring_nw, {1}];
    user{i,4}.bring_nw=[user{i,4}.bring_nw, {0}];    

    if N==6
        user{i,5}.want=[user{i,5}.want, a(i)];
        user{i,5}.bring_w=[user{i,5}.bring_w, {[]}];

        user{i,6}.no_want=[user{i,6}.no_want, a(i)];
        user{i,6}.bring_nw=[user{i,6}.bring_nw, {[]}];
    end
end

%reshape to slice in parfor
skip=reshape(skip(:,1:N),[length(a)*N 1]);
user=reshape(user,[length(a)*N 1]);

%matlabpool close
%matlabpool open 8
%maxNumCompThreads(4);
parfor k=1:length(user)
     cnn=cnn0;
     param=param0;
     
     tic
     if skip(k)   
         %if odds are too low or already answered, do not compute
         estimation=summ;
         prob=0; %flag to compute that option if the user chooses it.
         iter=0;
     else
         [estimation,prob,param,iter]=compute_summ(param,node,cnn,user{k},k,d,40,prefs,prune,lcl,summ);
     end

     if(sum(estimation(1:end-1))==0), estimation=summ; end
     fprintf('Time %f, iter %d, file %d\n',toc,iter,k);
     improv{k}=estimation;
     probs{k}=prob;
     params{k}=param;
end
%maxNumCompThreads(8);
%reshape to fit [#segments, simulations] 
improv=reshape(improv,[length(a),N]);
probs=reshape(probs,[length(a),N]);
params=reshape(params,[length(a),N]);

dif=cell2mat(cellfun(@(b) Kdist(summ(1:end-1),b(1:end-1,:)),mat2cell(cell2mat(improv),size(summ,1)*ones(1,size(improv,1)),size(improv,2)),'UniformOutput',0));

