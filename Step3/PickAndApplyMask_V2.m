%% Function to put individual mask into a larger canvas 
%  Feb 26, 2016 
%  Wenlong Xu 
%  Prasad Group 
%  Colorado State Univ. 
%  ------------------------------------------------------------------------
%  Version 2 
%  Doing the same thing while maintain the relative positions of cell and
%  nucleus. This spatial information is convey by variable offset. 
function [Out1, Out2, flag] = PickAndApplyMask_V2(In1, In2, idx, TYPE, offset)
%     In1 = LabledCells; 
%     In2 = CellGray; 
%     idx = jj; 
%     TYPE = SaveClass; 
    % In1 contains the masks for individual cells 
    % In2 contains the intensity info for these cells
    ThisOne = In1 == idx;
    Prop = regionprops(ThisOne, 'Image', 'BoundingBox'); 
    if ~isempty(Prop)
        flag = 1; 
        Cropped = Prop.Image;
        BB = Prop.BoundingBox;
        [Row, Col] = size(Cropped);
        PropCrop = regionprops(Cropped, 'Centroid');
        CenterX = PropCrop.Centroid(2)-offset(2);
        CenterY = PropCrop.Centroid(1)-offset(1);
        Canvas1 = zeros(1024);
        Canvas1 = Canvas1 ~= 0;
        XRange1 = (1:Row)-round(CenterX)+512;
        YRange1 = (1:Col)-round(CenterY)+512;
        %     [GX, GY] = meshgrid(YRange, XRange);
        Canvas1(XRange1, YRange1) = Cropped; 
        Out1 = Canvas1; 
        MaskedIn2 = cast(ThisOne, 'like', In2).*In2; 
        Canvas2 = zeros(1024, TYPE);
        XRange2 = ceil(BB(2):(BB(2)+BB(4)-1)); 
        YRange2 = ceil(BB(1):(BB(1)+BB(3)-1)); 
        Canvas2(XRange1, YRange1) = MaskedIn2(XRange2, YRange2); 
        Out2 = Canvas2; 
    else 
        flag = 0; 
        Out1 = zeros(1024); 
        Out2 = zeros(1024); 
    end
end % end of function 
