speed=1;
for i=1:length(fr)
    tic
    imshow(fr{i},'Parent',ctrl.video);
    pause(max(0,0.1/speed-toc))
    if get(ctrl.eval_seg,'Value')||get(ctrl.eval_summ,'Value')||get(ctrl.finish,'Value')||get(ctrl.seg_next,'Value')
        break
    end
    if paralel_batch
    if strcmp(b1.State,'finished')
        set(ctrl.eval_seg,'Visible','on')
    end
    end
end

if paralel_batch
set(ctrl.eval_seg,'Visible','on')
end

while ~get(ctrl.eval_seg,'Value')&&~get(ctrl.eval_summ,'Value')&&~get(ctrl.finish,'Value')&&~get(ctrl.seg_next,'Value')
    pause(0.5)
end