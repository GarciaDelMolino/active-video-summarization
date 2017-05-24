%-------------------------------------------------------------------------%
function [ c, varargout ] = myk_means( data, k , th )
% usage:
% [ cluster_centroids, clusterID, dist ] = kmeans( data, k , theta )
% where "data" is a matrix of Nobservations x Mdimensions
%-------------------------------------------------------------------------%

%initialization of the centroids:
%c=randi(max(max(data))+1,k,size(data,2))-1;
%if isempty(th), th= sqrt(sum(mean(data,1).^2,2))/(10*k); end
th=min([th sqrt(sum(mean(data,1).^2,2))/(10*k)]);
%c=data(floor(linspace(1,size(data,1),k+2)),:); 
%c=c(2:end-1,:); % select k samples as initial centroids
m=repmat(min(data,[],1),[k,1]);
M=repmat(max(data,[],1),[k,1]);
c=rand(k,size(data,2)).*(M-m)+m;
c=data(randsample(size(data,1),k),:);
d=th;
iter=0;
fprintf('iteration:\n    ');

while max(d)>=th
    % assignation of training points to clusters:
    [dc,cluster]=pdist2(double(c),double(data),'euclidean','Smallest',1); % returns a K(1)-by-my(length data) matrix I(cluster) containing indices of the observations in X(c) corresponding to the K(1) smallest pairwise distances in D(~)
    aux=cluster';
    % updating centroids
    n=zeros(k,size(data,2));    %number of points in each cluster k
    s=zeros(k,size(data,2));    %summatory of points in each cluster k
    for i=1:size(cluster,2)
        n(cluster(i),:)=n(cluster(i),:)+1;          %increment num of points in that cluster
        s(cluster(i),:)=s(cluster(i),:)+data(i,:);  %add new point to that cluster
    end
    old_c=c;
    c=(s./max(1,n));           %k centroids updated as mean of assigned points
    d=sqrt(sum((c-old_c).^2,2));    %k distances to old k centroids
    iter=iter+1;
    fprintf('\b\b\b\b%04d',iter);
end

if nargout>1
    varargout{1} = cluster;
    if nargout>2
        varargout{2} = dc;
    end
end
end