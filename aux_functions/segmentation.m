% very simple motion/illumination-driven. Minimum 2.5secs (25 frames)
% usage:
% [boundaries, desc_seg, q_seg]=segmentation([], illumination, motion, w,init,desc,q)
% OR
% [~, desc_seg, q_seg]=segmentation(boundaries, illumination, motion, w,init,desc,q)
% OR if no wheighting needed
% [boundaries, desc_seg, q_seg]=segmentation([], illumination, motion, [],[],desc,q)

default=25;
if illumination(1)~=illumination(2), illumination=floor(illumination/20)*20; end
if ~exist('boundaries','var')
    boundaries=find(illumination+motion-([illumination(2:end)+motion(2:end); illumination(end)+motion(end)])); %cutting frames
    b=find((([boundaries(2:end); boundaries(end)]-boundaries)>default*0.8)+(mod(boundaries,30)<10)); %select cuts over 30 frames and boundaries separated minimum 3secs
    boundaries=[1;boundaries(b(2:end))]; %boundaries (init frame)
    [~,b]=unique(floor(boundaries/default),'first');
    boundaries=boundaries(unique([b; find(floor(boundaries/default)~=round(boundaries/default))]));
    
    boundaries(([boundaries(2:end); boundaries(end)]-boundaries<0.5*default))=[]; %remove boundaries too close to the next
    d=[boundaries(2:end); boundaries(end)]-boundaries; 
    retouch=find(d>1.5*default); %add boundaries when space too wide
    boundaries=unique([boundaries; cell2mat(arrayfun(@(i) ...
        round(linspace(boundaries(retouch(i)),boundaries(retouch(i)+1),2+floor(d(retouch(i))/default))),...
        1:length(retouch),'UniformOutput',0))']);
end


desc_seg=cell2mat(arrayfun(@(i,k) mean(desc(i:k,:),1),boundaries,...
     [boundaries(2:end)-1; length(q)],'UniformOutput',0));
q_seg=cell2mat(arrayfun(@(i,k) mean([q(i:k) motion(i:k)],1),boundaries,...
     [boundaries(2:end)-1; length(q)],'UniformOutput',0));             %the greater the better
 
 boundaries=[boundaries; length(q)];

