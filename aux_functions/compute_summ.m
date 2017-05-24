function [estimation,prob,param,iter]=compute_summ(param,node,cnno,user,k,d,i,prefs,prune,lclo,summ) 
     stp=0;
     iter=0;
     param.l_big=[];
     param.l_small=0;
     param.pi_big=[];
     param.pi_small=0; 
   
     acum=[];
     p=[];
     if isempty(user.want)
        min_q=mean([median(node) mean(node)]);
     else
        min_q=min(mean([median(node) mean(node)]),mean(node(user.want)));
     end
     
     %Iterative convergence of optimal L and lambda (l_big, l_small, pi_big, pi_small)
     while (~stp)&&(iter<i) %stop even if conditions aren't met. We don't want an infinite loop.
        iter=iter+1;
        if iter==20, min_q=min([prctile(node,30),mean(node),mean(node(user.want))]); end
        
        %---------------------------------------------------%
        %                 Update to length, quality         %        
        cnn=cnno;
        cnn([3,6],:)=cnn([3,6],:)*param.l;
        lcl=lclo*param.pi;
        lcl(1,:)=lcl(1,:)*param.l;
        lcl=[2 length(lcl) -(reshape(lcl,[1,2*length(lcl)]))]; 
        
        %---------------------------------------------------%
        %                  user adaptation                  %        
        [lcl,cnn]=modify_to_user(lcl,cnn,user,param);
        
        %---------------------------------------------------%
        %                       MRF                         %       
        [estimation,~, prob]=mrf_computing(sprintf('tmp%d',k),lcl,cnn,0,prune);
        
        acum=[acum; logical(estimation(1:end-1)')];
        p=[p; prob(:,1)'];
        [param,~,stp]=update_parameters(node, find(estimation==1), param, cnn, d, min_q,user.want);        
     end
     
     if (sum(estimation(1:end-1))<param.min || sum(estimation(1:end-1))>param.max)
        prob=median(p);
        prob=[prob' 1-prob'];
        
        estimation(1:end-1)=0;
        [las,lo]=sort(sum(acum),'descend');

        idx=1:(min(find(las==las(param.max)))-1);
        if (param.max-length(idx))==1 %only one left, we pick it
            idx=[idx param.max];
        else %more than one left for that counting, linspace
            idx=[idx round(linspace(length(idx)+1,max(find(las==las(param.max))),...
                param.max-length(idx)))];
        end
        lo=lo(idx);
        estimation(lo(1:param.max))=1;
     end

    if sum(~ismember(user.want,find(estimation==1)))&&(~isempty(user.want))
        [lo,~]=sort(prob,'descend');
        estimation(1:end-1)=0;
        try
        estimation(unique([lo(1:param.min),user.want]))=1;
        catch
            estimation(unique([find(summ==1)',user.want]))=1;
        end
    end
end


function [param, cnn,stp]=update_parameters(node, summ, param, cnn, d,min_q,user)
stp=0;
%length constraints:
if length(summ)<param.min %l too big. make l smaller to get more 1s
    param.l_big=param.l;
    param.l=param.l_small+(param.l-param.l_small)*rand(1);%0.5;%*
elseif length(summ)>param.max %l too small. make l greater to get more 0s
    param.l_small=param.l;
    if isempty(param.l_big)
        param.l=param.l*(1+rand);
    else
        param.l=param.l+(param.l_big-param.l)*rand(1);
    end
%length is ok. Check quality constraints:
elseif (median(node(summ))< min_q)||sum(~ismember(user,summ)) %selection has bad quality, improve it prctile(node,50)
    param.pi_small=param.pi;
    param.l_big=[]; %reset upper and lower limits for length
    param.l_small=0;
    if isempty(param.pi_big)
        param.pi=param.pi*(1+rand(1));
    else
        param.pi=param.pi+(param.pi_big-param.pi)*rand(1);
    end
elseif mean(ismember(summ, find(node>prctile(node,(length(node)-ceil((length(summ)+1)/2))*100/length(node)))))>=0.8
    param.pi_big=param.pi;
    param.pi=param.pi-(param.pi-param.pi_small)*rand(1);%0.5;%
    param.l_big=[]; %reset upper and lower limits for length
    param.l_small=0;
else
    stp=1;
end


end

function [lcl,cnn]=modify_to_user(lcl,cnn,user,param)
% user selection: shots
% e.g.:
% [lcl,cnn]=modify_to_user(lcl,cnn,user)
%     user.want=[20,200];
%     user.bring_w={1,0}; % 1 to bring, 0 for no similars please, [] indiferent   
%     user.no_want=[];
%     user.bring_nw=[]; 
%     user.indiferent=[];

    
    if ~isempty(user.want)
  
        lcl(user.want*2+2)=-abs(param.pi*(param.ci*10)^param.ki);
        % bring forward             
        for i=find(~cellfun('isempty',user.bring_w)) % 1 to bring, 0 for no similars please, [] indiferent   
            loc=[find(cnn(1,:)==user.want(i)),find(cnn(2,:)==user.want(i))];
            cnn(4:5,loc)=cnn(4:5,loc)*param.l*param.pji*2*((-1)^(user.bring_w{i})); %make further negative for 0, possitive for 1. *param.l*param.pji*2: double than 00
            cnn(6,loc)=cnn(6,loc)*((-5)^user.bring_w{i}); %set equal to (00) if 1, or mantain as it is for 0.       
        end     
    end
    if ~isempty(user.no_want)
   
        lcl(user.no_want*2+1)=-(param.l*param.pi*100000);
        % bring forward             
        for i=find(~cellfun('isempty',user.bring_nw)) % 1 to bring, 0 for no similars please, [] indiferent   
            loc=[find(cnn(1,:)==user.no_want(i)),find(cnn(2,:)==user.no_want(i))];
            cnn(4:5,loc)=cnn(4:5,loc)*param.l*param.pji*2*((-1)^(~user.bring_nw{i}));%make further negative for 1, possitive for 0. 
            cnn(6,loc)=cnn(6,loc)*100; %no lo quiero bajo ninguna circunstancia!!       
        end        
    end
    if ~isempty(user.indiferent)
       lcl(user.indiferent*2+2)=lcl(user.indiferent*2+2)*(0.7+0.6*rand);
    end


    
end

function [summ,segments, probs]=mrf_computing(name,lcl,cnn,k,prune)
if (nargin<4)
  k= name(4:end); 
end
old_s=0;
if length(prune)<lcl(2)
    old_s=lcl(2);
    lcl=[2 length(prune) lcl(sort([prune*2+1 prune*2+2]))];
    
    [l,id]=ismember(cnn(1:2,:),prune);
    cnn=[id(:,l(1,:)&l(2,:));cnn(3:end,l(1,:)&l(2,:))];    
end

cnn=[size(cnn,2) reshape(cnn,[1,6*size(cnn,2)])];




[label, probs, energy]=mrf(double(lcl),double(cnn),double(4));


if min(min(probs))<-700
p=[probs(:,1);probs(:,2)];
p=[p(1:2:length(p)-1), p(2:2:length(p))];
p=exp(-(p-repmat(min(p,[],2),[1 2])));
probs=p./repmat(sum(p,2),[1 2]);
else
probs=exp(-[probs(:,1);probs(:,2)]);
probs=[(probs(1:2:length(probs)-1)./(probs(1:2:length(probs)-1)+probs(2:2:length(probs)))), ...
    (probs(2:2:length(probs))./(probs(1:2:length(probs)-1)+probs(2:2:length(probs))))];
end
summ=[label;energy];


segments=sum(summ(1:end-1)); 

if old_s
    p=probs;
    s=summ;
    
    summ=[zeros(old_s,1);s(end)];
    summ(prune((s==1)))=1;
    
    probs=[ones(old_s,1) zeros(old_s,1)];
    probs(prune,:)=p;
end
end

