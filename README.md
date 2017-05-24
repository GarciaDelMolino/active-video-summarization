# Active Video Summarization
Customized summarization of egocentric videos through minimal user interaction as described in [our AAAI-2017 paper](https://www.aaai.org/ocs/index.php/AAAI/AAAI17/paper/view/14856).

## Requirements:

	1) Caffe Deep Learning Framework and matcaffe wrapper (for global features calculation)
		Caffe main page: http://caffe.berkeleyvision.org/
		Good Linux installation tutorial: https://github.com/tiangolo/caffe/blob/ubuntu-tutorial-b/docs/install_apt2.md
		Model Zoo (places, objects, etc): https://github.com/BVLC/caffe/wiki/Model-Zoo 
	2) C++ compiler
	3) MATLAB
	4) avconv/ffmpeg or any other tool to extract the frames from the video.

## Dataset

AVS.m can be used as a demo with CSumm, as the features for some of the videos are provided (the videos can be downloaded [here](https://drive.google.com/open?id=0BxbxH0v4gna2d0xyMjlKUTRnZmM)). 
AVS has been tested on CSumm, UTEgo, and four videos in SumMe.
Alternatively, any other video data can be used, as long as the needed features can be extracted.

The provided image features and metadata labels have been obtained at 10fps. 
For AVS GUI to work as expected with such features, the original videos need to be converted to frames at that rate. 
AVS will execute the frame extraction automatically using avconv. 
Alternatively, you can choose to run in your terminal 

	mkdir VIDEOid
	avconv -i VIDEOid.mp4 -r 10 -f image2 VIDEOid/VIDEOid_%04d.png

(For Windows 10, we recommend using _Bash on Ubuntu on Windows_ to perform this operation)



## Citation

If you use this code or CSumm dataset, please cite the following paper:

        GARCIA DEL MOLINO, A.; BOIX, X.; LIM, J.H.; TAN, A.H. 
        Active Video Summarization: Customized Summaries via On-line Interaction with the User. 
        AAAI Conference on Artificial Intelligence, North America, feb. 2017. 
        Available at: <https://www.aaai.org/ocs/index.php/AAAI/AAAI17/paper/view/14856>.

## MRF

Our implementation of the MRF is a modification of the MAXFLOW library by Yuri Boykov. Please check their license and README files for how to use and cite it.

There are two implementations for MRF: one for windows, one for unix systems. Make sure you are using the right one for your machine. To compile, go to the MRF folder and:

	Windows: 
		run MakeWin on the VS console. (Change LIBPATH for your MATLAB path and version)
		run make_matlab in MATLAB.

	Unix:	
		run make on the console.
		run make_matlab in MATLAB.

## How To

Run AVS.m for a walk-through of the system. AVS will first extract all video frames at 10fps using avconv. 
This will only work on Unix systems. For Windows 10, we recommend using _Bash on Ubuntu on Windows_ to perform this operation.

AVS.m uses batch and paralel programming. If matlabpool is not possible in your machine, change all batch calls to simple script calls to speed the computation.

## Function structure:

	AVS.m 	-- extract_frames (once done, set the conditional to 0)
		-- descriptor (batch) -- load_features -- extract_cnn
		-- segmentation (batch)
		-- passive (batch) (requires object_dir and places_dir to be modified)
		-- init_crf (batch) -- my_kmeans
		-- compute_summ
		-- what_to_query (batch) -- compute_summ
		-- movie_show

