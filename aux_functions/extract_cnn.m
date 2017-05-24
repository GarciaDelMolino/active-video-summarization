function [ cnn, cnn_tot] = extract_cnn( path, frames, proto)
%COMPUTE_CNN Given a path and struct of images (e.g. pwd and struct 
%obtained from dir(*.jpg)), and an int to define your model (places or objects, low or high level), this 
%function returns the cnn output for both models
%Usage: [ cnn, cnnTOT ] = compute_cnn(path, images, modelFlag )
%e.g.   path=pwd;
%       images=dir([path '*.jpg']);
%
% Model flag: 1 or 3 for objects; 2 or 4 for places. 
%        1,2 for last layer; 3 4 for lower level feature.


%Change your preferred model here, and/or update path:
if mod(proto,2)
    model='caffe-rc2/models/bvlc_reference_caffenet/bvlc_reference_caffenet.caffemodel';
    if proto>2
        proto='caffe-rc2/models/bvlc_reference_caffenet/deploy2.prototxt';
    else
        proto='caffe-rc2/models/bvlc_reference_caffenet/deploy.prototxt';
    end
else
    model='caffe-rc2/models/places/places205CNN_iter_300000_upgraded.caffemodel';
    if proto>2
        proto='caffe-rc2/models/places/places205CNN_deploy_upgraded.prototxt';
    else
        proto='caffe-rc2/models/places/places205CNN_deploy_upgraded.prototxt';
    end
end

cnn=[];

if isempty(frames)
    frames=dir([path, '*.png']);
else
    if isstruct(frames)
        frames=arrayfun(@(b) [path '/' b.name] ,frames,'UniformOutput',0);
    end
end



if nargout>1
cnn_tot=[];
end

% init caffe    
caffe('init', proto, model, 'test')
caffe('set_mode_cpu');
fprintf('Done with init\n');

% frames analysis 
c=fix(clock);
fprintf('total: %d frames; time: %d:%d:%d, progress:   0%s',size(frames,1),...
    c(4),c(5),c(6),char(8240)); 



for i=1:size(frames,1)
    % prepare oversampled input
    % input_data is Height x Width x Channel x Num
    %input_data = {prepare_image(imread([path, frames(i).name]))};
    
    im=imread(frames{i});
    if strcmp(path(end-4:end-1),'KT_1')||strcmp(path(end-4:end-1),'KT_2')||strcmp(path(end-4:end-1),'LJ_1')
        im=permute(im(:,end:-1:1, :),[2 1 3]);
    end

    if ~mod(proto,2)
        input_data = {prepare_image_FPV(im)};
    else
        input_data = {prepare_image_places(im)};
    end

    % do forward pass to get scores
    % scores are now Width x Height x Channels x Num
    scores = caffe('forward', input_data);

    scores = scores{1};
    scores = squeeze(scores);  
    if nargout>1, cnn_tot(:,:,i)=scores; end
    scores = max(scores,[],2);

    cnn(i,:)=scores';

    fprintf('\b\b\b\b%3.d%s',floor(1000*i/size(frames,1)),char(8240)); %3. %s 1000*[...],char(8240)
end


c=fix(clock);
fprintf('\nFinished at %d:%d:%d\n',c(4),c(5),c(6)); 
end



% ------------------------------------------------------------------------
function images = prepare_image_places(im)
% ------------------------------------------------------------------------
%subplot(3,4,1), imshow(im)

d = load('places_mean.mat');
IMAGE_MEAN = d.image_mean;
IMAGE_DIM = 256;
CROPPED_DIM = 227;

% resize to fixed input size
im = single(im);

if size(im,1)<size(im,2)
    im = imresize(im, [IMAGE_DIM NaN], 'bilinear');
else
   im = imresize(im, [NaN IMAGE_DIM], 'bilinear');
end
% permute from RGB to BGR (IMAGE_MEAN is already BGR)
im = im(:,:,[3 2 1]) - imresize(IMAGE_MEAN,[size(im,1) size(im,2)],'bilinear');

% oversample (4 corners, center, and their y-axis flips)
images = zeros(CROPPED_DIM, CROPPED_DIM, 3, 10, 'single');
indicesi = [0 size(im,1)-CROPPED_DIM] + 1;
indicesj = [0 size(im,2)-CROPPED_DIM] + 1;
curr = 1;
for i = indicesi
  for j = indicesj
    images(:, :, :, curr) = ...
        im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :);
        %permute(im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :), [2 1 3]);
    images(:, :, :, curr+5) = images(:,end:-1:1,  :, curr);
    curr = curr + 1;
  end
end
centeri = floor(indicesi(2) / 2)+1;
centerj = floor(indicesj(2) / 2)+1;
images(:,:,:,5) = ...
    permute(im(centeri:centeri+CROPPED_DIM-1,centerj:centerj+CROPPED_DIM-1,:), ...
        [2 1 3]);
images(:,:,:,10) = images(end:-1:1, :, :, curr);

%pause()
end


% ------------------------------------------------------------------------
function images = prepare_image_FPV(im)
% ------------------------------------------------------------------------
%subplot(3,4,1), imshow(im)

d = load('ilsvrc_2012_mean');
IMAGE_MEAN = d.image_mean;
IMAGE_DIM = 256;
CROPPED_DIM = 227;
IMAGE_DIM = CROPPED_DIM*1.9;

% resize to fixed input size
im = single(im);

if size(im,2)<size(im,1)
    im = imresize(im, [IMAGE_DIM NaN], 'bilinear');
else
   im = imresize(im, [NaN IMAGE_DIM], 'bilinear');
end
% permute from RGB to BGR (IMAGE_MEAN is already BGR)
im = im(:,:,[3 2 1]) - imresize(IMAGE_MEAN,[size(im,1) size(im,2)],'bilinear');

% oversample (4 corners, center, and their y-axis flips)
images = zeros(CROPPED_DIM, CROPPED_DIM, 3, 10, 'single');
indicesi = [0 size(im,1)-CROPPED_DIM] + 1;
indicesj = [0 size(im,2)-CROPPED_DIM] + 1;
curr = 1;
for i = indicesi
  for j = indicesj
    images(:, :, :, curr) = ...
        im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :);
        %permute(im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :), [2 1 3]);
    images(:, :, :, curr+5) = images(:,end:-1:1,  :, curr);
    curr = curr + 1;
  end
end
if size(im,2)<size(im,1)
im = imresize(im, [NaN CROPPED_DIM], 'bilinear');
else
im = imresize(im, [CROPPED_DIM NaN], 'bilinear');    
end
indicesi = [0 size(im,1)-CROPPED_DIM] + 1;
indicesj = [0 size(im,2)-CROPPED_DIM] + 1;
centeri = floor(indicesi(2) / 2)+1;
centerj = floor(indicesj(2) / 2)+1;
images(:,:,:,5) = ...
    permute(im(centeri:centeri+CROPPED_DIM-1,centerj:centerj+CROPPED_DIM-1,:), ...
        [2 1 3]);
images(:,:,:,10) = images(end:-1:1, :, :, curr);

if 0
h=subplot(3,2,1);
imshow(im/255)
set(h, 'pos', [0 .64 .30 .25]);  
for i=1:10
h=subplot(3,4,i+2);
imshow(images(:,:,:,i)/255)
set(h, 'pos', [.253*mod(i+1,4) .64-.31*floor((i+1)/4) .24 .25]);  
end
end
%pause()
end


% ------------------------------------------------------------------------
function images = prepare_image(im) %CAFFE-provided one. Not used.
% ------------------------------------------------------------------------
d = load('ilsvrc_2012_mean');
IMAGE_MEAN = d.image_mean;
IMAGE_DIM = 256;
CROPPED_DIM = 227;

% resize to fixed input size
im = single(im);
im = imresize(im, [IMAGE_DIM IMAGE_DIM], 'bilinear');
% permute from RGB to BGR (IMAGE_MEAN is already BGR)
im = im(:,:,[3 2 1]) - IMAGE_MEAN;

% oversample (4 corners, center, and their x-axis flips)
images = zeros(CROPPED_DIM, CROPPED_DIM, 3, 10, 'single');
indices = [0 IMAGE_DIM-CROPPED_DIM] + 1;
curr = 1;
for i = indices
  for j = indices
    images(:, :, :, curr) = ...
        permute(im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :), [2 1 3]);
    images(:, :, :, curr+5) = images(end:-1:1, :, :, curr);
    curr = curr + 1;
  end
end
center = floor(indices(2) / 2)+1;
images(:,:,:,5) = ...
    permute(im(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:), ...
        [2 1 3]);
images(:,:,:,10) = images(end:-1:1, :, :, curr);
end

