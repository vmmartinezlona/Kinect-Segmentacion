%% _______________________________ Acquire image

img = imread('./Images/1.png');

%% _______________________________ Thresholding the image on each color plane

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









