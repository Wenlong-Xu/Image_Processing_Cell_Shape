%% Using only matlab to pipeline the thresholding 
%  June 2, 2016 
%  Wenlong Xu 
%  Prasad Group 
%  Colorado State Univ. 
%  ------------------------------------------------------------------------
% Inputs into the code 
WorkingDir = 'C:\temSpace\ProjectForFall\Cameron\2\AKT_FN_A_TIFF'; 
SpecStr = 'AKT_FN_A_*'; 
OutputDir = 'C:\temSpace\ProjectForFall\Cameron\2\AKT_FN_A_TIFF'; 
Output_Folder = 'Step 1'; 

Nuc_affix = '_DAPI.TIF';
Actin_affix = '_FITC.TIF';
%  ------------------------------------------------------------------------
global Threshold
IfMakeDir = dir(fullfile(OutputDir, Output_Folder)); 
if isempty(IfMakeDir)
    mkdir(fullfile(OutputDir, Output_Folder))
end

IfMakeDir2 = dir(fullfile(OutputDir, Output_Folder, SpecStr(1:end-2)));
if isempty(IfMakeDir2)
    mkdir(fullfile(OutputDir, Output_Folder, SpecStr(1:end-2)))
end
fout = fopen(fullfile(OutputDir, Output_Folder, [SpecStr(1:end-2), 'Tresholds.txt']), 'w'); 
fprintf(fout, 'Slide_Name\t Nuc_Treshold\t Actin_Treshold\n '); 

AllSlides = dir(fullfile(WorkingDir, SpecStr)); 
NumSlides = length(AllSlides); 

for ii = 1:NumSlides
    SlideName = AllSlides(ii).name; 
    Output_Path = fullfile(OutputDir, Output_Folder, SpecStr(1:end-2), SlideName); 
    IfMakeDir3 = dir(Output_Path);
    if isempty(IfMakeDir3)
        mkdir(Output_Path)
    end

    fprintf(['We are now working on ', SlideName, '.\n']); 
    
    NucOri = imread(fullfile(WorkingDir, SlideName, [SlideName, Nuc_affix])); 
    % if the image are in rgb format, convert it to gray scale 
    if size(NucOri, 3) ~= 1 
        NucOri = rgb2gray(NucOri); 
    end
    
    [row, col] = size(NucOri); 
    Total_Points = row*col; 
    % First threshold the Nuc image 
    f1 = UI_Threshold(NucOri);
    uiwait(f1);
    Nuc_Threshold = Threshold; 
    NucBW = im2bw(NucOri, Nuc_Threshold);
    
    ActinOri = imread(fullfile(WorkingDir, SlideName, [SlideName, Actin_affix])); 
    % if the image are in rgb format, convert it to gray scale
    if size(ActinOri, 3) ~= 1
        ActinOri = rgb2gray(ActinOri);
    end
    f2 = UI_Threshold(ActinOri);
    uiwait(f2);
    Actin_Threshold = Threshold; 
    ActinBW = im2bw(ActinOri, Actin_Threshold);
    
    %% Calculate the value used for thresholding in the original intensity 
    % Output the recalculated threshold value used for thresholding for
    % future reference 
    fprintf(fout, '%s\t %d\t %d\n ', SlideName, Nuc_Threshold, Actin_Threshold); 
    
    %% Save the thresholded and adjusted images for futher processing 
    ActinBW = imfill(ActinBW, 'holes'); 
    NucBW   = imfill(NucBW,   'holes'); 
    
    imwrite(ActinBW, fullfile(Output_Path, [SlideName, '_ActinMask.bmp']));
    imwrite(NucBW,   fullfile(Output_Path, [SlideName, '_NucMask.bmp'])); 
    imwrite(ActinOri.*cast(ActinBW, 'like', ActinOri), fullfile(Output_Path, [SlideName, '_ActinInt.tif'])); 
    imwrite(NucOri  .*cast(NucBW, 'like', NucOri),     fullfile(Output_Path, [SlideName, '_NucInt.tif'])); 
end
fclose all; 










