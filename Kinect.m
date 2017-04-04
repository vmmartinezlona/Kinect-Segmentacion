%% _______________________________ Acquire image

img = imread('./Images/2.jpg');
%img = imread('./Images/3.jpg');
%img = imread('./Images/4.png');

%kinect
% Create the objects for the color and depth sensros
vidColor = videoinput('kinect', 1);
vidDepth = videoinput('kinect', 2);

% Get the source propierties for the depth device
srcDepth = getselectedsource(vidDepth);

%Set the frames per trigger for both devices to 1
vidColor.FramesPerTigger = 1;
vidDepth.FramesPerTigger = 1;

%set the trigger repeat for both devices to 10, in order to acquire 11
%frames from both (the color sensor and the depth sensor)
vidColor.TriggerRepeat = 10;
vidDepth.TriggerRepeat = 10;

%COnfigure the camero for manual triggering for both sensors
triggerconfig([vidColor vidDepth], 'manual');

%Start both video objects
start([viColor vidDepth]);

%Trigger the devices, then get acquire data
% Trigger 10 times to get the frames
for i = 1:11
    %trigger bith objects
    trigger([vidColor vidDepth])
    %get the acquired frames and metadata
    [imgColor, ts_color, metaData_Color] = getdata(vidColor);
    [imgDepth, ts_depth, metaData_Depth] = getdata(vidDepth);
end

%% _______________________________ Thresholding the image on each selColor plane

img = im2double(img);
% Compute the size
[row col plane] = size(img);

% Extract indivudials plane from RGB image
imgR = squeeze(img(: , : , 1));
imgG = squeeze(img(: , : , 2));
imgB = squeeze(img(: , : , 3));

% Thresholding on individual planes
imgBinaryR = im2bw(imgR, graythresh(imgR));
imgBinaryG = im2bw(imgG, graythresh(imgG));
imgBinaryB = im2bw(imgB, graythresh(imgB));

% To define objects
imgBinary = imcomplement(imgBinaryR & imgBinaryG & imgBinaryB);

imshow(imgBinary);


%% _______________________________ Remove imperfection and strange objects

% Morphologial opening
se = strel('disk', 7);
imgClean = imopen(imgBinary, se);

% Fill holes and clear border
imgClean = imfill(imgClean, 'holes');
imgClean = imclearborder(imgClean);

imshow(imgClean);

%% _______________________________ Compute the number of objects in the image

% Segmented gray-level image
[labels, numLabels] = bwlabel(imgClean);
disp(['Number of objects detected: ' num2str(numLabels)]);

%% _______________________________ Identify the selColor of each object

% Auxiliar matrix
rLabel = zeros(row, col);
gLabel = zeros(row, col);
bLabel = zeros(row, col);

% Get average selColor vector for each labeled region
for i = 1 : numLabels
    rLabel(labels == i) = median(imgR(labels == i));
    gLabel(labels == i) = median(imgG(labels == i));
    bLabel(labels == i) = median(imgB(labels == i));
end

% Give the respective selColor to each object
imgLabel = cat(3 , rLabel , gLabel, bLabel);
imshow(imgLabel)
impixelinfo(gcf);

%% _______________________________ Choose the objects of the desired selColor

% Get the desired selColor
[x y] = ginput(1);
selColor = imgLabel(floor(y), floor(x) , :);

% Convert to LAB selColor space
C = makecform('srgb2lab');
imgLAB = applycform(imgLabel, C);
imgSelLAB = applycform(selColor, C);

% Extract a* and b* values
imgA = imgLAB(: , : , 2);
imgB = imgLAB(: , : , 3);
imgSelA = imgSelLAB(1 , 2); % extract a*
imgSelB = imgSelLAB(1 , 3); % extract a*

% Compute distance from selected selColor
% Gradient
distThresh = 10;
imgMask = zeros(row , col);
imgDist = hypot(imgA - imgSelA , imgB - imgSelB);
imgMask(imgDist < distThresh) = 1;
[cLabel, cNum] = bwlabel(imgMask);
imgSeg = repmat(selColor , [row , col , 1]).*repmat(imgMask , [1 , 1 , 3]);
imshow(imgSeg);






    
