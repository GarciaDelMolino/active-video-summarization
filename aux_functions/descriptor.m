%create descriptor
addpath(genpath('aux_functions')) 

%parfor i=1:length(home)
for i=1:length(home)
frames{i}=dir([home{i},'/*.png']);
frames{i}=arrayfun(@(b) [home{i} '/' b.name] ,frames{i},'UniformOutput',0);
fprintf('Computing folder %s, %d%d%d%d%d%d',home{i}, fix(clock))
% load or extract features:
[animals{i}, objects{i}, places{i}, people{i},gps{i}, illumination{i}, motion{i},q{i}]=...
    load_features(frames{i},[home{i} '/labels_8_0.1.mat'],[home{i} '/places_8_0.1.mat'], ...
    [home{i} '/quality.mat'],[home{i} '/metadata.mat'],[home{i} '/original_meta.mat']);
fprintf(' Done\n')
end
%matlabpool close

frames=cat(1,frames{:});
id=(0:(length(frames)-1))'/(length(frames)-1);
animals=cat(1,animals{:});
objects =cat(1,objects{:});
places =cat(1,places{:});
people =cat(1,people{:});
gps=cat(1,gps{:});
illumination =cat(1,illumination{:});
motion =cat(1,motion{:});
q=cat(1,q{:});


desc=[animals objects places people gps id];
init=cumsum([1 size(animals, 2), size(objects, 2), size(places, 2), size(people, 2), size(gps, 2), size(id, 2)]);

%clear people gps id animals objects places