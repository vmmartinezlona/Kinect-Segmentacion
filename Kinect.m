clc;
clear all;

%% _______________________________ Acquire image

%img = imread('./Images/2.jpg');
img = imread('./Images/3.jpg');
%img = imread('./Images/4.png');

%imgDepth = imread('./Images/5.png');

% %kinect
% % Create the objects for the color and depth sensros
% % vidColor = videoinput('kinect', 1);
% % vidDepth = videoinput('kinect', 2);
% 
% % Get the source propierties for the depth device
% % srcDepth = getselectedsource(vidDepth);
% 
% %Set the frames per trigger for both devices to 1
% % vidColor.FramesPerTigger = 1;
% % vidDepth.FramesPerTigger = 1;
% 
% %set the trigger repeat for both devices to 10, in order to acquire 11
% %frames from both (the color sensor and the depth sensor)
% % vidColor.TriggerRepeat = 10;
% % vidDepth.TriggerRepeat = 10;
% 
% %COnfigure the camero for manual triggering for both sensors
% %triggerconfig([vidColor vidDepth], 'manual');
% 
% %Start both video objects
% %start([viColor vidDepth]);
% 
% %Trigger the devices, then get acquire data
% % Trigger 10 times to get the frames
% for i = 1:11
%     %trigger bith objects
%     trigger([vidColor vidDepth])
%     %get the acquired frames and metadata
%     [imgColor, ts_color, metaData_Color] = getdata(vidColor);
%     [imgDepth, ts_depth, metaData_Depth] = getdata(vidDepth);
% end
% 
% Get the joint locations for the first person in world
% coordinates using the JointWorldCoordinates property.
% Since this is the person in position 1, the index uses 1
% metaData.JointWorldCoordinates(:,:,1)
% (x y z) in meters


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

%% _______________________________ Remove imperfection and strange objects

% Morphologial opening
se = strel('disk', 7);
imgClean = imopen(imgBinary, se);

% Fill holes and clear border
imgClean = imfill(imgClean, 'holes');
imgClean = imclearborder(imgClean);

%% _______________________________ Compute the number of objects in the image

% Segmented gray-level image
[labels, numLabels] = bwlabel(imgClean);
disp(['Number of objects detected: ' num2str(numLabels)]);

%% _______________________________ Identify the color of each object

% Auxiliar matrix
rLabel = zeros(row, col);
gLabel = zeros(row, col);
bLabel = zeros(row, col);

% Get average color vector for each labeled region
% numLabels == numObjects in the scene
for i1 = 1 : numLabels
    rLabel(labels == i1) = median(imgR(labels == i1));
    gLabel(labels == i1) = median(imgG(labels == i1));
    bLabel(labels == i1) = median(imgB(labels == i1));
end

% Give the respective color to each object
imgLabel = cat(3 , rLabel , gLabel, bLabel);
imshow(imgLabel);
% gcf = current figure handle. 
% impixelinfo(gcf) == impixel (imgLabel)
impixelinfo(gcf);

% Segment the objects in the original image with the compute mask
imgFinal = img.* SegmentationMask(row, col, imgLabel);
imshow(imgFinal);

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
imgSelB = imgSelLAB(1 , 3); % extract b*

% Compute distance from selected selColor
% Gradient
distThresh = 10;
imgMask = zeros(row , col);
imgDist = hypot(imgA - imgSelA , imgB - imgSelB);
imgMask(imgDist < distThresh) = 1;
[cLabel, cNum] = bwlabel(imgMask);
imgSeg = repmat(selColor , [row , col , 1]).*repmat(imgMask , [1 , 1 , 3]);

% Segment the objects in the original image with the compute mask
imgFinal = img.* SegmentationMask(row, col, imgSeg);
imshow(imgFinal);
%improfile;

% Compute number of objects of the selColor

% Segmented gray-level image
[labels, numLabels] = bwlabel(imgMask);
disp(['Number of objects detected: ' num2str(numLabels)]);

%P = mean(impixel(imgMask), 2);

[xi, yi, P] = impixel(imgFinal)


numSelObj = size(P,1)

% Compute the depth with the limits os the Kinect's specifications
% 0 == 1.0 m ; 255 == 3.0 m
upLim  = 1.0; lowLim = 3.0; 

for i1 = 1 : numSelObj
    x = xi(i1); y = yi(i1); 
    depth = imgMask(y, x) / 255 * (upLim - lowLim) + lowLim;
    disp(['Distance obejct ', num2str(i1), ' = ', num2str(depth)]);     
end