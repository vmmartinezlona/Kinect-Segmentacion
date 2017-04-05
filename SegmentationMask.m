function [ imgMask ] = SegmentationMask( row, col, imgSource )
% Create the mask for segmentation, this functions ensure that all the
% regions of interest in the mask are white.

% Create auxiliar matrix for keep the values
imgAuxM = zeros(row, col);

for i1 = 1 : row
    for j1 = 1 : col 
        % If some pixel is diferent to black whe assume that is a pixel of
        % a region of interest and make it white
        if(imgSource(i1, j1) ~= 0)
            imgAuxM(i1, j1) = 1;
        else
            imgAuxM(i1, j1) = 0;
        end
    end
end

% For calculations the mask has to be 3-dim
imgMask(:, : , 1) = imgAuxM;
imgMask(:, : , 2) = imgAuxM;
imgMask(:, : , 3) = imgAuxM;

end

