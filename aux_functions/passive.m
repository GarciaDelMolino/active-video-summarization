%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                       passive preferences                             %%         
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load(objects_dir,'hypernymsAnimals','hypernymsLv1','words','mask_animals','mask_objectsLv1');
c=load(places_dir, 'cat');

[~,labels]=ismember(hypernymsLv1,words.id,'rows');
labels=[hypernymsAnimals; cellfun(@(i) strtrim(i),mat2cell(words.word(labels,:),ones(1,length(labels)),size(words.word,2)),'UniformOutput',0);c.cat];

aux=sum([animals objects places].*([animals objects places]>0.1));
aux=[arrayfun(@(i) max(aux(find(mask_animals(:,i)))),1:size(mask_animals,2))...
    arrayfun(@(i) max(aux(size(mask_animals,2)+find(mask_objectsLv1(:,i)))),1:size(mask_objectsLv1,2))...
    aux(size(animals,2)+size(objects,2)+1:end)];
[lo,la]=sort(aux,'descend');

passive_pref=labels(la(lo>0));  



