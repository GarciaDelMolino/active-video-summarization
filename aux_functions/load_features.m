
function [animals, objects, places, people,gps, illumination, motion,q]=load_features(frames,file_obj_ppl, file_pl, file_q, file_meta, file_meta_original)
% Returns features for animals, objects and places (CNN); people counts 
% (if such information is available as external file); gps location and 
% motion (from metadata if available); illumination (from metadata if 
% available, or pixel average otherwise); and quality assessment.
%
% [animals, objects, places, people,gps, illumination, motion,q]=
%       load_features(frames, file_obj_ppl, file_pl, file_q)
% where, e.g.:
% file_obj_ppl='./20141123_161609_161609/labels_8_0.1.mat'
% file_pl='./20141123_161609_161609/places_8_0.1.mat';
% file_q='./20141123_161609_161609/quality.mat'
% file_meta='./20141123_161609_161609/metadata.mat';
% file_meta_original='./20141123_161609_161609/original_meta.mat'

people=0;
window=8;

%% Objects
if exist(file_obj_ppl,'file')
    load(file_obj_ppl, 'cnn','people');
else
    tic
    [cnn_obj,cnn_obj_tot]=extract_cnn(pwd, frames, 1);
    people=zeros(size(cnn_obj,1),1);

    %windowing
    cnn_ext=cat(1,cnn_obj,flipud(cnn_obj(size(cnn_obj,1)-window:size(cnn_obj,1)-1,:)),flipud(cnn_obj(2:window+1,:))); %fill blank lines for shifting
    ext=[];
    for i=-window:window
        ext=cat(3,ext,circshift(cnn_ext,[i 0])); %baja todo i posiciones
    end
    cnn_ext=ext(1:size(cnn_obj,1),:,:);
    cnn=max(cnn_ext,[],3);

    %save mats
    save(file_obj_ppl,'cnn_obj','cnn_obj_tot','cnn', 'people');
    clear cnn_obj_tot cnn_obj
    toc
end
%animals=cnn(:,1:398)*mask_animals;
%objects=cnn(:,399:end)*mask_objectsLv1;
animals=cnn(:,1:398);
objects=cnn(:,399:end);
clear cnn

%% Places
if exist(file_pl,'file')
load(file_pl, 'cnn');
else
    tic
    [cnn_pl,cnn_pl_tot]=extract_cnn(folder, frames, 2);
    
    %windowing
    cnn_ext=cat(1,cnn_pl,flipud(cnn_pl(size(cnn_pl,1)-window:size(cnn_pl,1)-1,:)),flipud(cnn_pl(2:window+1,:))); %fill blank lines for shifting
    ext=[];
    for i=-window:window
        ext=cat(3,ext,circshift(cnn_ext,[i 0])); %baja todo i posiciones
    end
    cnn_ext=ext(1:size(cnn_pl,1),:,:);
    cnn=max(cnn_ext,[],3);

    %save mats
    save(file_pl,'cnn_pl','cnn_pl_tot', 'cnn');
    clear cnn_pl_tot  cnn_pl
    toc
end
places=cnn;


%% Quality

if exist(file_q,'file'), load(file_q,'q'); end
if ~exist('q','var')
    tic
    sz=size(imread(frames{1}));
    sz=size(sz,1)*size(sz,2);
    q=cell2mat(arrayfun(@(k) ...
        sum(sum(((edge(rgb2gray(imread(frames{k})),'Prewitt',0.1,'both'))),1))/sz,...
        1:length(frames),'UniformOutput',0)');
    toc
    save(file_q,'q');
end
if size(q,2)>size(q,1), q=q'; end

%% Motion
if exist(file_meta,'file')
    load(file_meta, 'state'); 
    motion=state.annotation(end-length(frames)+1:end,:)*[1 0 0.5]';              %standing=1, moving=0, interacting=0.5.
else
    motion=ones(size(frames)); 
end

%% People
if ~max(people)                                 %if people CV analysis not available, go to annotation.
    if exist(file_meta,'file')
    load(file_meta,'num_people');
    people=(num_people.annotation(end-length(frames)+1:end,:)*([0 1 3 5 6]')/6);
    else
    people=zeros(size(frames));   
    end
else
    people=people/max(people);  
    if size(people,1)<size(objects,1), people=[people; people((end-size(objects,1)+size(people,1)+1):end)]; end
end

%% GPS & Illumination
if exist(file_meta_original,'file')
    load(file_meta_original);
    if exist('metadata','var')
    gps=[metadata.Latitude((end-length(frames)+1):end), metadata.Longitude((end-length(frames)+1):end)];
    illumination=metadata.Light((end-length(frames)+1):end);
    illumination=(illumination-min(illumination))/(max(illumination)-min(illumination));
    else
    gps=zeros(size(frames,1),2);
    if ~exist('illumination','var')
    illumination=cell2mat(arrayfun(@(k) mean(mean(mean(imread(frames{k})))),...
        1:length(frames),'UniformOutput',0)');
    end
    end
else
    gps=zeros(size(frames,1),2);
    illumination=cell2mat(arrayfun(@(k) mean(mean(mean(imread(frames{k})))),...
        1:length(frames),'UniformOutput',0)');
end
    
end
