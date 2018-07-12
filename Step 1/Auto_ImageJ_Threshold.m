%% Using MIJ (the Interface b/w Matlab and ImageJ) to pipeline the thresholding 
%  May 20, 2016 
%  Wenlong Xu 
%  Prasad Group 
%  Colorado State Univ. 
%  ------------------------------------------------------------------------
%% Start the MIJ 
%  Before running the following code, first run these 3 lines first to
%  start the MIJ. 
% javaaddpath('C:\Program Files\MATLAB\R2016b\java\jar\mij.jar'); 
% javaaddpath('C:\Program Files\MATLAB\R2016b\java\jar\ij.jar'); 
% MIJ.start 
%  
%  End the MIJ 
%  After finishing the pre-thresholding, enter the following to end the
%  ImageJ: 
%  MIJ.exit 
%  ------------------------------------------------------------------------
% Inputs into the code 
WorkingDir = 'C:\temSpace\Spring2018\2\SAOS2_GAA_C1.TIFF\'; 
SpecStr = 'SAOS2_GAA_C1_*'; 
OutputDir = WorkingDir;%'C:\Users\xuwl\Dropbox\CellShape\For Jackie\DLM8_GDA_TIFF\'; 
Output_Folder = 'Output_SAOS2_GAA_C1'; 
Bitdepth = 16; 
Nuc_affix = '_DAPI.TIF';
Actin_affix = '_FITC.TIF';
%  ------------------------------------------------------------------------
IfMakeDir = dir([OutputDir, Output_Folder]); 
if isempty(IfMakeDir)
    mkdir([WorkingDir, Output_Folder])
end
MaxInt = 2^Bitdepth-1; 
IfMakeDir2 = dir([OutputDir, Output_Folder, '\', SpecStr(1:end-2)]);
if isempty(IfMakeDir2)
    mkdir([OutputDir, Output_Folder, '\', SpecStr(1:end-2)])
end
fout = fopen([OutputDir, Output_Folder, '\', SpecStr(1:end-2), 'Tresholds.txt'], 'w'); 
fprintf(fout, 'Slide_Name\t Nuc_Treshold\t Actin_Treshold\n '); 

AllSlides = dir([WorkingDir, SpecStr]); 
NumSlides = length(AllSlides); 

for ii = 1:NumSlides
    SlideName = AllSlides(ii).name; 
    Output_Path = [OutputDir, Output_Folder, '\', SpecStr(1:end-2), '\', SlideName]; 
    IfMakeDir3 = dir(Output_Path);
    if isempty(IfMakeDir3)
        mkdir(Output_Path)
    end

    fprintf(['We are now working on ', SlideName, '.\n']); 
    
    NucOri = imread([WorkingDir, SlideName, '\', SlideName, Nuc_affix]); 
    % if the image are in rgb format, convert it to gray scale 
    if size(NucOri, 3) ~= 1 
        NucOri = rgb2gray(NucOri); 
    end
    ActinOri = imread([WorkingDir, SlideName, '\', SlideName, Actin_affix]); 
    % if the image are in rgb format, convert it to gray scale
    if size(ActinOri, 3) ~= 1
        ActinOri = rgb2gray(ActinOri);
    end
    [row, col] = size(NucOri); 
    Total_Points = row*col; 
    % First threshold the Nuc image 
    [ind_count, ~] = hist(reshape(NucOri, 1, Total_Points), 0:1:MaxInt);
    Threshold = find(cumsum(ind_count) > (1-1e-4)*Total_Points, 1, 'first');
    NucAd = imadjust(NucOri, [0; Threshold/MaxInt], [], 1); 
    
    MIJ.createImage(NucAd)
    MIJ.run('Threshold...')
    
    pause 
    NucBW = MIJ.getCurrentImage; 
    NucBW = NucBW ~= 0; 
    MIJ.closeAllWindows 
    % Then threshold the Actin Image 
    [ind_count, ~] = hist(reshape(ActinOri, 1, Total_Points), 0:1:MaxInt); 
    Threshold = find(cumsum(ind_count) > (1-1e-4)*Total_Points, 1, 'first');
    ActinAd = imadjust(ActinOri, [0; Threshold/MaxInt], [], 1); 
    
    MIJ.createImage(ActinAd)
    MIJ.run('Threshold...')
    pause 
    ActinBW = MIJ.getCurrentImage; 
    ActinBW = ActinBW ~= 0; 
    MIJ.closeAllWindows 
    
    %% Calculate the value used for thresholding in the original intensity 
    Unique_Nuc = unique (NucOri.*cast(NucBW, 'like', NucOri)); 
    
    Thres_Nuc = double(Unique_Nuc(2))/MaxInt; 
    
    Unique_Actin = unique (ActinOri.*cast(ActinBW, 'like', ActinOri));

    Thres_Actin = double(Unique_Actin(2))/MaxInt;
    
    % Output the recalculated threshold value used for thresholding for
    % future reference 
    fprintf(fout, '%s\t %d\t %d\n ', SlideName, Thres_Nuc, Thres_Actin); 
    
    %% Save the thresholded and adjusted images for futher processing 
    ActinBW = imfill(ActinBW, 'holes'); 
    NucBW   = imfill(NucBW,   'holes'); 
    imwrite(ActinBW, [Output_Path, '\', SlideName, '_ActinMask.bmp']);
    imwrite(NucBW,   [Output_Path, '\', SlideName, '_NucMask.bmp']); 
    imwrite(ActinAd.*cast(ActinBW, 'like', ActinAd), [Output_Path, '\', SlideName, '_ActinInt.tif']); 
    imwrite(NucAd.*cast(NucBW, 'like', NucAd), [Output_Path, '\', SlideName, '_NucInt.tif']); 
end
fclose all; 










