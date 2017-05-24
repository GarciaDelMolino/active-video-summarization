videos=dir('*.mp4');

parfor i=1:size(videos,1)
    e=videos(i,1).name(1:strfind(videos(i,1).name,'.')-1);
    if exist(e,'dir') 
        if isempty(dir(sprintf('%s/%s_*.png',e, e)))
            system([sprintf('avconv -i %s -r 10 -f image2 %s/%s',...
                videos(i,1).name, e,e) '_%04d.png'])
        end
        
    else 
        system(sprintf('mkdir %s',e))
        system([sprintf('avconv -i %s -r 10 -f image2 %s/%s',...
            videos(i,1).name, e,e) '_%04d.png'])
    end
end

clear e