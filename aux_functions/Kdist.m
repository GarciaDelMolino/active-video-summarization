function d=Kdist(summ, a)
    %%
    %summ=evolution(:,1:end-1,2);
    %a=a(:,end);
    l=sum(summ)-sum(a);
    
    if 0
        
    %summary is shorter than candidate, we need to simulate additional segments in summ:
    tic
    aux=find(l<0);
    if ~isempty(aux)
    loc=arrayfun(@(i) nchoosek(setdiff(find(a(:,i)),find(summ)),-l(i)),aux,'UniformOutput',0); %setdiff to simulate segments that are not already in summ.
    d(aux)=cell2mat(arrayfun(@(i) median(1-corr([find(a(:,aux(i)));find(~a(:,aux(i)))],...
        cell2mat(arrayfun(@(j) [unique([find(summ);loc{i}(j,:)']);setdiff(find(~summ),loc{i}(j,:)')],1:size(loc{i},1),'UniformOutput',0)),...
        'type','kendall')),1:length(aux),'UniformOutput',0));
    end
    
    %summary has same lenght as candidate:
    if ~isempty(find(l==0))
    d(l==0)=1-corr([find(summ);find(~summ)], cell2mat(arrayfun(@(i) [find(a(:,i));find(~a(:,i))],find(l==0),'UniformOutput',0 )),'type','kendall');
    end
    
    %summary is larger than candidate, we need to simulate additional segments in candidate:
    aux=find(l>0);
    if ~isempty(aux)
    loc=arrayfun(@(i) nchoosek(setdiff(find(summ),find(a(:,i))),l(i)),aux,'UniformOutput',0);
    d(aux)=cell2mat(arrayfun(@(i) median(1-corr([find(summ);find(~summ)],...
        cell2mat(arrayfun(@(j) [unique([find(a(:,aux(i)));loc{i}(j,:)']);setdiff(find(~a(:,aux(i))),loc{i}(j,:)')],1:size(loc{i},1),'UniformOutput',0)),...
        'type','kendall')),1:length(aux),'UniformOutput',0));
    end
    toc
    
    else
        
        
        b=logical(eye(length(summ)));
        aux=find(l<0);
        if ~isempty(aux) %summary is shorter than candidate, we need to simulate additional segments in summ:
        loc=arrayfun(@(i) nchoosek(setdiff(find(a(:,i)),find(summ)),-l(i)),aux,'UniformOutput',0); %setdiff to simulate segments that are not already in summ.
        loc=cellfun(@(i) b(:,i),loc,'UniformOutput',0);
        d(aux)=cell2mat(arrayfun(@(i) median(earth_mov(a(:,aux(i)),...
            logical(repmat(summ,[1,size(loc{i},2)])+loc{i}))),1:length(aux),'UniformOutput',0));
        end

        %summary has same lenght as candidate:
        if sum(l==0)
        d(l==0)=earth_mov(summ, a(:,l==0));
        end

        %summary is larger than candidate, we need to simulate additional segments in candidate:
        aux=find(l>0);
        if ~isempty(aux)
        loc=arrayfun(@(i) nchoosek(setdiff(find(summ),find(a(:,i))),l(i)),aux,'UniformOutput',0);
        loc=cellfun(@(i) b(:,i),loc,'UniformOutput',0);
        d(aux)=cell2mat(arrayfun(@(i) median(earth_mov(summ,...
            logical(repmat(a(:,aux(i)),[1,size(loc{i},2)])+loc{i}))),1:length(aux),'UniformOutput',0));
        end     
        
    end
end

function [d]=earth_mov(a,b)
    %d=sum(abs(repmat(cumsum(a),[1,size(b,2)])-cumsum(a)*sum(a)./repmat(sum(b),[size(a,1),1])));
    d=sum(abs(repmat(cumsum(a),[1,size(b,2)])-cumsum(b)));
end
