%% Save individual cell into separated folders 
%  Feb 26, 2016 
%  Wenlong Xu 
%  Prasad Group 
%  Colorado State Univ. 
%  ------------------------------------------------------------------------
% Version information 
% Updated on May 18, 2016 
% This version only processes images with two channels: DAPI for nuclei and
% FITC for actin.  
%  ------------------------------------------------------------------------
% Now we have the outlines of actin network, cell membrane and nuclei, then
% we need to separate these into individual cells. 
%  ------------------------------------------------------------------------
%% First, read in all images we are going to use: 
WorkingDir = 'H:\BackUp2018_01_07\PC_Cdrive\Tempspace\Programs\Data\CancerDrug2016Oct18\Matlab_101520\DUNN_TIFF\DUNN_PP2_C_GDA\'; 
SpecStr = 'DUNN_PP2_C_GDA_*'; 
Output_Folder = 'DUNN_PP2_C_SepCells\'; 
AllSlides = dir([WorkingDir, SpecStr]); 
NumSlides = length(AllSlides); 
CellCount = 0; 
for ii = 1:1%NumSlides??????????
    SlideName = AllSlides(ii).name; 
%     SlideName = 'DUNN_GAA_9'; 
    fprintf(['We are now working on ', SlideName, '.\n']); 
    % NOTE: Here we are assuming the SlideName (the subfolder name  
    % containing images to be analyzed) and the image tag are same. 
%     [FileName, PathName, ~] = uigetfile('.tif', 'Select Labled Cells from CellProfiler!'); 
    LabledCells = imread([WorkingDir, SlideName, '\', SlideName, '_NucIntActinImage.tif']); 
    LabledNuclei = imread([WorkingDir, SlideName, '\', SlideName, '_NucIntNucImage.tif']); 
    CellOutlines = imread([WorkingDir, SlideName, '\', SlideName, '_NucInt_ActinOutlines.bmp']); 
    Num_Cells = max(max(LabledCells)); 
    Num_Nuc = max(max(LabledNuclei)); 
    if Num_Cells < 255 % This means we do not need uint 16 to save the cells 
        LabledCells = uint8(LabledCells); 
        LabledNuclei = uint8(LabledNuclei); 
    end
    NucGray = imread([WorkingDir, SlideName, '\', SlideName, '_NucInt.tif']); 
    ActinGray = imread([WorkingDir, SlideName, '\', SlideName, '_ActinInt.tif']); 
    
    if strcmp(class(NucGray), 'uint16') 
        NucGray = uint8(255.*double(NucGray)./max(max(double(NucGray)))); 
        ActinGray = uint8(255.*double(ActinGray)./max(max(double(ActinGray)))); 
    end
    %% Second, separate each cell and put it into a separate image 
    %  Creat a folder for the separated cells 
%     Loc1 = find(PathName == '\'); 
%     PathName2 = PathName(1:Loc1(end-1)); 
    IfMakeDir = dir([WorkingDir, Output_Folder]); 
    if isempty(IfMakeDir)
        mkdir([WorkingDir, Output_Folder]); 
    end
    SaveClass = class(NucGray); 
    % ---------------------------------------------------------------------
    % NOTE: Becuase we are using two-step reconstruction (nuclei --> actin
    % and actin --> membrane), it is possible to have the discrenpcy 
    % between the nuclei number and actin number. So, we will have a
    % quality control step before doing the cell separation. 
    FilteredNuc = zeros(size(LabledNuclei), 'uint8'); 
    FilteredActin = zeros(size(LabledNuclei), 'uint8'); 
    FilteredCellIdx = 0;  
    for zz = 1:Num_Cells 
        ThisNuc = LabledNuclei == zz; 
        Prop0 = regionprops(ThisNuc, 'Centroid'); 
        CentroidX = ceil(Prop0.Centroid(2)); 
        CentroidY = ceil(Prop0.Centroid(1)); 
%         Position = ceil([CentroidX, CentroidY]); 
        ActinIdx = LabledCells(CentroidX, CentroidY); 
        if ActinIdx ~= 0
            % This means this is a valid object with info on all 3 channels
            FilteredCellIdx = FilteredCellIdx + 1; 
            Prop1 = regionprops(LabledNuclei == zz, 'PixelIdxList');
            NucPixelIdx = Prop1.PixelIdxList; 
            FilteredNuc(NucPixelIdx) = FilteredCellIdx; 
            Prop2 = regionprops(LabledCells == ActinIdx, 'PixelIdxList'); 
            ActinPixelIdx = Prop2.PixelIdxList; 
            FilteredActin(ActinPixelIdx) = FilteredCellIdx; 
        end
    end
    % Using this method cannot rule out the possibility that one "cell"
    % holds multiple nuclei. 
    % The previous step should give us a incremental vector from 0 to 
    % FilteredCellIdx. If not, then that is where the over-writting
    % happens. We can get rid of the objects do not spanning all 3
    % channels. 
    Temp1 = unique(FilteredNuc); 
    Temp2 = unique(FilteredActin); 
    Temp4 = 0:1:FilteredCellIdx; 
    MissIdx1 = Temp4(~ismember(Temp4, Temp1')); 
    MissIdx2 = Temp4(~ismember(Temp4, Temp2')); 
    MissIdx = unique([MissIdx1, MissIdx2]); 
    if ~isempty(MissIdx)
        for xx = MissIdx 
            FilteredNuc(FilteredNuc == xx) = 0; 
            FilteredActin(FilteredActin == xx) = 0; 
        end 
    end
    % ---------------------------------------------------------------------
    % Then, we need to clear the cells touching the borders 
    [row, col] = size(FilteredActin); 
    Left = unique(FilteredActin(:, 1)); 
    Right = unique(FilteredActin(:, col)); 
    Upper = unique(FilteredActin(1, :)); 
    Lower = unique(FilteredActin(row, :)); 
    BorderIdx = unique([Left', Right', Upper, Lower]); 
    BorderIdx(BorderIdx == 0) = []; 
    if isempty(MissIdx) 
        FinalCellIdx = 1:1:FilteredCellIdx; 
    else 
        Temp = 1:1:FilteredCellIdx; 
        FinalCellIdx = Temp(~ismember(Temp, MissIdx)); 
    end
    %% Visual Inspection and Manual Processing if needed 
    %  Cells touching the image borders are not directly removed from the 
    %  maskes. So they are still visible in the visual inspection. In the
    %  separation part, they are avoided from the cell indexes. 
%     FilteredNuc=LabledNuclei;
%     FilteredAcin=LabledCells;
    
    [FilteredNuc, FilteredActin] = ManualProcessingV3... 
    (FilteredActin, FilteredNuc, ActinGray, NucGray, CellOutlines); 
    FinalCellIdx = unique(FilteredActin)'; 
    FinalCellIdx(FinalCellIdx == 0) = []; 
    %FinalCellIdx=1%???????????????
    % ---------------------------------------------------------------------
    %% Separate cells and save them individually 
    for jj = FinalCellIdx 
        [ActinMask, ActinInt, flagActin] = PickAndApplyMask(FilteredActin, ActinGray, jj, SaveClass); 
        [NucMask, NucInt, flagNuc] = PickAndApplyMask(FilteredNuc, NucGray, jj, SaveClass); 
        
        This_Actin = FilteredAcin == jj;
        Prop_Actin = regionprops(This_Actin, 'Centroid'); 
        This_Nuc   = FilteredNuc   == jj;
        Prop_Nuc   = regionprops(This_Nuc,   'Centroid'); 
        offset = Prop_Nuc(1).Centroid - Prop_Actin(1).Centroid; 
        [Nuc_Sep_Mask, Nuc_Sep_Int, flagNuc] = PickAndApplyMask_V2(FilteredNuc, NucGray, jj, class(NucGray), offset); 
        if flagActin && flagNuc
            % save these six sub-images into according file folders. 
            CellStr = [SlideName, '_Cell', num2str(jj)]; 
            IfMakeDir2 = dir([WorkingDir, Output_Folder, '\', CellStr]); 
            if isempty(IfMakeDir2)
                mkdir([WorkingDir, Output_Folder, '\', CellStr])
            end

            imwrite(ActinMask, [WorkingDir, Output_Folder, '\', CellStr, '\', CellStr, '_ActinMask.bmp']); 
            imwrite(NucMask, [WorkingDir, Output_Folder, '\', CellStr, '\', CellStr, '_NucMask.bmp']); 
            
            imwrite(ActinInt, [WorkingDir, Output_Folder, '\', CellStr, '\', CellStr, '_ActinInt.tif']); 
            imwrite(NucInt, [WorkingDir, Output_Folder, '\', CellStr, '\', CellStr, '_NucInt.tif']); 
            imwrite(Nuc_Sep_Mask, [WorkingDir, Output_Folder, '\', CellStr, '\', CellStr, '_NucMask2.bmp']); 
        else 
            FinalCellIdx(FinalCellIdx == jj) = []; 
        end
         
            
    end
    %% Save location information of all cells 
    fout1 = fopen([WorkingDir, Output_Folder, '\', SlideName, '_loc_info.txt'], 'w'); 
    fprintf(fout1, 'CellIdx\t Location\n'); 
    % We have five possible locations for all cells: 
    % border, isolated, edge, inside, missed
    for zz = FinalCellIdx
        zz = uint8(zz); 
        savemode = 0; 
        if ~ismember(zz, MissIdx)
            ThisCell = FilteredActin == zz;
            SE = strel('square', 3);
            ThisCell2 = imdilate(ThisCell, SE);
            ThisBdry = bwboundaries(ThisCell2);
            ThisBdryPixelList = ThisBdry{1};
            BdryX = ThisBdryPixelList(:, 1);
            BdryY = ThisBdryPixelList(:, 2);
            Num_Points = length(BdryX);
            NeiborghList = zeros(1, Num_Points, 'uint8');
            for jj = 1:Num_Points
                NeiborghList(jj) = FilteredActin(BdryX(jj), BdryY(jj));
            end
            NhoodCellIdx = unique(NeiborghList);
            Num_Nhood = length(NhoodCellIdx);
            Percentage = zeros(1, Num_Nhood);
            for jj = 1:Num_Nhood
                Percentage(jj) = length(find(NeiborghList == NhoodCellIdx(jj)))/Num_Points;
            end
            if ismember(zz, BorderIdx)
                savemode = 1; 
                fprintf(fout1, '%d\t %s\n', zz, 'Border'); 
            else 
                if ismember(0, NhoodCellIdx) && length(NhoodCellIdx) == 1 
                    % Isolated Cells 
                    fprintf(fout1, '%d\t %s\n', zz, 'Isolated'); 
                elseif ismember(0, NhoodCellIdx) && length(NhoodCellIdx) > 1 
                    % On the edges of cell clump 
                    % If the attachment to other cells are small (<1%), we
                    % still consider it as isolated cell 
                    savemode = 1; 
                    Condition = Percentage(1) > 0.99; 
                    if Condition 
                        fprintf(fout1, '%d\t %s\n', zz, 'Isolated'); 
                    else 
                        fprintf(fout1, '%d\t %s\n', zz, 'Edge'); 
                    end 
                elseif ~ismember(0, NhoodCellIdx) 
                    % inside the cell clump 
                    savemode = 1; 
                    fprintf(fout1, '%d\t %s\n', zz, 'Inside'); 
                end
            end
        else
            fprintf(fout1, '%d\t %s\n', zz, 'Missed'); 
        end
        
        if savemode == 1 
            CellStr = [SlideName, '_Cell', num2str(zz)]; 
            fout2 = fopen([WorkingDir, Output_Folder, '\', CellStr, '\', CellStr, '_loc_info.txt'], 'w'); 
            fprintf(fout2, 'NeighborIdx\t Percentage\n'); 
            for jj = 1:Num_Nhood 
                fprintf(fout2, '%d\t %f\n', NhoodCellIdx(jj), Percentage(jj)); 
            end
            fclose(fout2); 
        end
    end
    fclose(fout1); 
end
