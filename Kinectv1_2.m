clc;
clear all;

% %% _______________________________ Acquire image

disp('Obtencion de imagenes');
option = input('Para iniciar el Kinect presione 1, para leer de disco presione 2 \n');

if option == 1
    %%{
    %%setup Kinect v1.6 Runtime
    %%targetinstaller;
    %%supportPackageInstaller
    %%Kinect adaptor and devices
    imaqhwinfo;
    info=imaqhwinfo('kinect');
    %%Create videoinput object for color Stream
    info.DeviceInfo(1);
    colorVid=videoinput('kinect',1,'RGB_640x480');
    %preview(colorVid);
    img=getsnapshot(colorVid);
    %%{
    %%Videoinput Object for Depth Stream
    info.DeviceInfo(2);
    depthVid=videoinput('kinect',2,'Depth_640x480');
    %%captura la imagen
    depthImage=getsnapshot(depthVid);
    %preview(depthVid);
    %}
    %% Introduce getdata
    start(depthVid);
    [frameDataDepth, timeDataDepth, metaDataDepth]= getdata(depthVid);

    metaDataDepth;
    %}
    
else
    img = imread('./Images/original_color.png');
    depthImage = imread('./Images/original_depth.png');
    
end

%% _______________________________ Thresholding the image on each selColor plane
img = im2double(img);
% 
% figure(2), imshow(img);
% figure(3), imshow(depthImage);

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
% gcf = current figure handle. 
% impixelinfo(gcf) == impixel (imgLabel)
imshow(imgLabel);
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
% In kinect distThresh = 1
% In simulate image = 10
% It depends of the image
distThresh = 1;
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
disp(['Number of selected color objects detected: ' num2str(numLabels)]);

%P = mean(impixel(imgMask), 2);

[xi, yi, P] = impixel(imgFinal);


numSelObj = size(P,1);

% Compute the depth with the limits os the Kinect's specifications
% 0 == 1.0 m ; 255 == 3.0 m
upLim  = 3.0; lowLim = 0.8; 
depthImage = im2double(depthImage);
max = max(max(max(depthImage)));

depth = zeros(1, numSelObj);

for i1 = 1 : numSelObj
    x = xi(i1); y = yi(i1); 
    depth(i1) = depthImage(y, x) / max * (upLim - lowLim) + lowLim;
    disp(['Distance obejct ', num2str(i1), ' = ', num2str(depth(i1)), ' meters' ]);     
end

imgResult = insertText(imgFinal, [xi yi], depth, 'AnchorPoint','LeftBottom');
imshow(imgResult); 


imwrite(img, './Original_Image.png');
imwrite(depthImage, './Depth_Image.png');
imwrite(imgFinal, './Final_image.png'); 
imwrite(imgResult, './Result_image.png'); 