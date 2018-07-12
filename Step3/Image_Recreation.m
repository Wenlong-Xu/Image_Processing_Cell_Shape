%% Function to Recreate Images Containing only the Regions Specified 
%  October 26, 2015 
%  Wenlong Xu 
%  Prasad Group 
%  Colorado State Univ. 
%  ------------------------------------------------------------------------
function OUT = Image_Recreation(I, Props, S)
%OUT = Image_Recreation(I, Props, Size) recreates the binary images of size
% S, a two-component vector specifying the image size, contains only the
% regions of interest specified in vector I from the PixelList contained in
% structure Props. 
OUT = zeros(S, 'uint8'); 
for ii = 1:length(I) 
    Pixels = Props(I(ii)).PixelList; 
    Num = size(Pixels, 1); 
    for jj = 1:Num 
        OUT(Pixels(jj, 2), Pixels(jj, 1)) = 255; 
    end
end
OUT = OUT ~= 0; 

end % end of function 