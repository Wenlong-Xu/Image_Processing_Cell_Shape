%% Visual inspection of the cell profiler results 
%  Feb 28, 2016 
%  Wenlong Xu 
%  Prasad Group 
%  Colorado State Univ. 
%  ------------------------------------------------------------------------
% Updated on May 18, 2016 
% This version only processes images with two channels: DAPI for nuclei and
% FITC for actin. 
% -------------------------------------------------------------------------
%% Introduction 
%  It is not necessary that the cell de-clumping results from CellProfiler
%  are all satisfactory. This code will enable the invisual inspection of
%  these results and if the judge is not satisfied, it will enable the
%  judge to remove the cell from future analysis. 
%  Work flow 
% 1) If you are satisfied with the CellProfiler segmentation results? 
%    OR if you want to do something on the cell boundaries? 
%       Yes -- Continue; 
%       No  -- Exit; 
% 2) If yes to 1), what you want to do? 
%       Remove entire cells (cells on boundaries are removed automately)
%       Reset the boundaries b/w two cells manually 
%       Remove a subregion from a cell 
%  ------------------------------------------------------------------------
%% NOTE 
%  When selecting cells to remove and especially to adjust the boundaries,
%  do your best to click on nuclei. 
%  Updated on March 15, 2016 
%  Due to false dividing of nuclei into two dividing cells, we updated a
%  new operation to combine two cells and their associated nuclei into one.
%  ------------------------------------------------------------------------
%% First, read in all images we are going to use: 
% [FileName, PathName, ~] = uigetfile('.tif', 'Select Labled Cells from CellProfiler!'); 
% LabledCells = imread([PathName, FileName(1:end-4), 'CellImage.tif']); 
% LabledActin = imread([PathName, FileName(1:end-4), 'ActinImage.tif']); 
% LabledNuclei = imread([PathName, FileName(1:end-4), 'NucImage.tif']); 
% 
% if Num_Cells < 255 % This means we do not need uint 16 to save the cells 
%     LabledCells = uint8(LabledCells); 
%     LabledActin = uint8(LabledActin); 
%     LabledNuclei = uint8(LabledNuclei); 
% end
% NucGray = imread([PathName, FileName]); 
% ActinGray = imread([PathName, FileName(1:end-5), '2.TIF']); 
% CellGray = imread([PathName, FileName(1:end-5), '3.TIF']); 
% CellOutlines = imread([PathName, FileName(1:end-4), '_CellOutlines.bmp']); 
% -------------------------------------------------------------------------
function [MaskNuc, MaskCell] = ManualProcessingV3... 
    (LabledCells, LabledNuclei, CellGray, NucGray, CellOutlines)
%%
% OriColor Image saves all the original information for the visual check 
[row, col] = size(CellGray); 
OriColor = zeros([row, col, 3], 'uint8'); 
OriColor(:, :, 1) = CellOutlines; 
OriColor(:, :, 2) = imadjust(CellGray); 
OriColor(:, :, 3) = imadjust(NucGray); 

f1 = figure; 
imshow(OriColor) 
set(gcf, 'Position', get(0, 'Screensize')); 
option_control = 1; 
If_Start_Over_All = 0; 
NucBackup = LabledNuclei;
CellBackup = LabledCells; 
OutlinesBackup = OriColor(:, :, 1); 
WorkingOutlines = OutlinesBackup; 
If_Boundaries_Adjusted = 0; 
SaveNewBoundaries = zeros(row, col, 'uint8'); 
while option_control == 1 
    if If_Start_Over_All == 1; 
        LabledNuclei = NucBackup;
        LabledCells = CellBackup; 
        WorkingOutlines = OutlinesBackup; 
        f1 = figure; 
        imshow(OriColor)
        set(gcf, 'Position', get(0, 'Screensize')); 
    end
    % Make sure that we only work with the copy of Labeled images.
    % Only change the Labeled images after the changes are finalized.
    GhostNuc = LabledNuclei;
    GhostCell = LabledCells; 
    GhostBoundary = WorkingOutlines; 
    cut_or_not = questdlg('Do you want to modify the cell masks?', 'Choice', 'Yes', 'No', 'Yes');
    switch cut_or_not
        case 'Yes'
            % Creat caches for the cell masks 
            Options = questdlg('What do you want to do?', 'Operations', 'Remove/Combine', 'Adjust', 'Cut', 'Remove/Combine'); 
            switch Options
                case 'Remove/Combine' 
                    % Make attemptive changes on cell masks 
                    [x, y, ~] = get_figure_points(gca);
                    close(f1); 
                    Which2do = questdlg('Specify Remove/Combine!', 'Futher Operations', 'Remove', 'Combine', 'Remove'); 
                    switch Which2do 
                        case 'Remove'
                            Num2Remove = length(x); 
                            for ii = 1:Num2Remove
                                % Because we use the aligned cell indexes, it is OK
                                % to use any of the channels to determine the index
        %                         NucIdx = GhostNuc(ceil(y(ii)), ceil(x(ii)));
        %                         ActinIdx = GhostActin(ceil(y(ii)), ceil(x(ii)));
                                CellIdx = GhostCell(ceil(y(ii)), ceil(x(ii)));
                                GhostBoundary = GhostBoundary.*uint8(~(GhostCell == CellIdx)); 
                                GhostNuc(GhostNuc == CellIdx) = 0;
                                GhostCell(GhostCell == CellIdx) = 0; 
                            end 
                            
                            % This is a newly added operation to combine two cells selected into one
                        case 'Combine'
                            Num2Adjust = length(x);
                            % Selected cells are all assigned with the cell index
                            % of the first selected cell:
                            Idx2Go = GhostCell(ceil(y(1)), ceil(x(1)));
                            for ii = 1:Num2Adjust
                                CellIdx = GhostCell(ceil(y(ii)), ceil(x(ii)));
                                GhostBoundary = GhostBoundary.*uint8(~(GhostCell == CellIdx)); 
                                GhostNuc(GhostNuc == CellIdx) = Idx2Go;
                                GhostCell(GhostCell == CellIdx) = Idx2Go; 
                            end
                            % Modify the boundary accordingly 
                            RAM = zeros([row, col], 'uint8');
                            RAM(GhostCell == Idx2Go) = 1;
                            RAM = RAM ~= 0;
                            ThisBoundary = bwboundaries(RAM);
                            Num_Boundary = length(ThisBoundary);
                            Boundary_Length = zeros(1, Num_Boundary);
                            for jj = 1: Num_Boundary
                                Boundary_Length(jj) = length(ThisBoundary{jj});
                            end
                            ThisBoundary = ThisBoundary{Boundary_Length == max(Boundary_Length)};
                            for jj = 1:length(ThisBoundary(:, 1))
                                GhostBoundary(ThisBoundary(jj,1), ThisBoundary(jj,2)) = 255;
                            end
                            
                    end
                case 'Adjust' 
                    % The new boundary is inherently assigned with the cell
                    % index of the original cell the boundary pixels are at. 
                    % Make attemptive changes on cell masks  
                    [CellX, CellY, ~] = get_figure_points(gca); 
                    close(f1); 
                    Num2Adjust = length(CellX); 
                    RAMCell = zeros([row, col], 'uint8'); 
                    for ii = 1:Num2Adjust
                        CellIdx = GhostCell(ceil(CellY(ii)), ceil(CellX(ii))); 
                        RAMCell(GhostCell == CellIdx) = 1; 
                    end 
                    % Till this far, we identified the cells we want to
                    % adjust boundaries. Then, we need to reset the
                    % boundaries. 
                    If_Cutting = 1;
                    If_Start_Over_Adjust = 0; 
                    RAM = zeros([row, col], 'uint8'); 
                    while If_Cutting == 1 
                        Color = zeros([row, col, 3], 'uint8'); 
                        if If_Boundaries_Adjusted == 1
                            % This means we need to adjust the boundaries to be
                            % displayed.
                            Color(:, :, 1) = OriColor(:, :, 1) + SaveNewBoundaries; 
                        else 
                            Color(:, :, 1) = OriColor(:, :, 1); 
                        end
                        Color(:, :, 1) =    Color(:, :, 1).*uint8(RAMCell).*uint8(GhostCell ~= 0);
                        Color(:, :, 2) = OriColor(:, :, 2).*uint8(RAMCell).*uint8(GhostCell ~= 0);
                        Color(:, :, 3) = OriColor(:, :, 3).*uint8(RAMCell).*uint8(GhostNuc ~= 0); 

                        f2 = figure;
                        imshow(Color)
                        set(gcf, 'Position', get(0, 'Screensize')); 
                        if If_Start_Over_Adjust == 1
                            RAM = zeros([row, col], 'uint8'); 
                            If_Start_Over_Adjust = 0; 
                        end
                        
                        % Regular manual cutting step
                        h = imfreehand(gca);
                        position = wait(h);
                        x = position(:, 1);
                        y = position(:, 2);
                        RAM = Connect_Points(RAM, x, y, 1, 0);
                        RAMCellCut = RAMCell & ~RAM; 
                        Boundaries = bwboundaries(RAMCellCut); 
                        
                        Objs_Cell = regionprops(RAMCellCut, 'Area', 'BoundingBox', 'PixelIdxList');
                        Num_Objs_Cell = size(Objs_Cell, 1);
                        
%                         All_Area = zeros(1, Num_Objs_Cell); 
%                         for kk = 1:Num_Objs_Cell
%                             All_Area(kk) = Objs_Cell(kk).Area; 
%                         end
                        
                        ValidRegion = zeros(1, 2); 
                        for kk = 1:Num_Objs_Cell
                            Check1 = ismember(ceil(CellX(1))*row + ceil(CellY(1)), Objs_Cell(kk).PixelIdxList); 
                            Check2 = ismember(ceil(CellX(2))*row + ceil(CellY(2)), Objs_Cell(kk).PixelIdxList); 
                            if Check1 
                                ValidRegion(1) = kk; 
                            end
                            if Check2
                                ValidRegion(2) = kk; 
                            end 
                        end
                        
                        close(f2); 
                        f3 = figure; 
                        imshow(RAMCellCut)
                        set(gcf, 'Position', get(0, 'Screensize')); 
                        hold on 
                        ValidRegion = unique(ValidRegion); 
                        
                        % For the regions are not valid, we remove them: 
                        for kk = 1:Num_Objs_Cell 
                            if ~ismember(kk, ValidRegion)
                                RemovePixelIdxList = Objs_Cell(kk).PixelIdxList; 
                                GhostNuc(RemovePixelIdxList) = 0;
                                GhostCell(RemovePixelIdxList) = 0;
                                GhostBoundary(RemovePixelIdxList) = 0;
                            end
                        end
                        
                        for kk = ValidRegion
                            Box = Objs_Cell(kk).BoundingBox;
                            thisBoundary = Boundaries{kk};
                            text(Box(1)+Box(3), Box(2)-20, num2str(kk), 'FontSize', 16, 'FontWeight', 'Bold', 'Color', [0 1 0])
                            plot(thisBoundary(:,2), thisBoundary(:,1), 'g', 'LineWidth', 2);
                        end
                        hold off
                        continue_or_not = questdlg(['Do you have ', num2str(length(ValidRegion)), ' Cells?'], 'Cutting', 'Yes', 'No', 'Start Over', 'Yes');
                        switch continue_or_not
                            case 'Yes'
                                If_Cutting = 0; 
                                If_Boundaries_Adjusted = 1; 
                                SaveNewBoundaries = SaveNewBoundaries + uint8(RAM).*255; 
                                % Based on the new boundaries to reassign cell indexes:
                                % The reassigned boundaries should not change the
                                % belonging of nuclei, so we can still use the nuclei
                                % as the seeds for new index assignment. 
                                for ii = 1:Num2Adjust
                                    CellIdx = GhostCell(ceil(CellY(ii)), ceil(CellX(ii))); 
                                    % The order of cells in the clicking is
                                    % not same as the order in the region
                                    % measurement 
                                    for jj = 1:length(ValidRegion) 
                                        Check = ismember(ceil(CellX(ii))*row + ceil(CellY(ii)), Objs_Cell(ValidRegion(jj)).PixelIdxList); 
                                        if Check 
                                            nn = ValidRegion(jj); 
                                        end
                                    end
                                    NewCellPixelList = Objs_Cell(nn).PixelIdxList; 
                                    GhostCell(NewCellPixelList) = CellIdx; 
                                    GhostBoundary(NewCellPixelList) = 0; 
                                   
                                end
                                
                            case 'No'
                                If_Cutting = 1; 
                                If_Boundaries_Adjusted = 1;
                                SaveNewBoundaries = SaveNewBoundaries + uint8(RAM).*255; 
                            case 'Start Over'
                                If_Cutting = 1;
                                If_Start_Over_Adjust = 1; 
                                If_Boundaries_Adjusted = 0; 
                                SaveNewBoundaries = zeros(row, col, 'uint8'); 
                        end
                        close(f3); 
                    end
                    % Modify the boundary accordingly 
                    for ii = 1:Num2Adjust
                        CellIdx = GhostCell(ceil(CellY(ii)), ceil(CellX(ii)));
                        RAM3 = zeros([row, col], 'uint8');
                        RAM3(GhostCell == CellIdx) = 1; 
                        RAM3 = RAM3 ~= 0;
                        ThisBoundary = bwboundaries(RAM3);
                        Num_Boundary = length(ThisBoundary);
                        Boundary_Length = zeros(1, Num_Boundary);
                        for jj = 1: Num_Boundary
                            Boundary_Length(jj) = length(ThisBoundary{jj});
                        end
                        ThisBoundary = ThisBoundary{Boundary_Length == max(Boundary_Length)};
                        for jj = 1:length(ThisBoundary(:, 1))
                            GhostBoundary(ThisBoundary(jj,1), ThisBoundary(jj,2)) = 255;
                        end
                    end
                    
                case 'Cut' 
                    If_Cutting = 1; 
                    If_Start_Over_Cut = 1; 
                    Num_Cut = 0; 
                    while If_Cutting == 1 
                        Num_Cut = Num_Cut + 1; 
                        if If_Start_Over_Cut == 1 
                            RAM = zeros([row, col], 'uint8'); 
                            If_Start_Over_Cut = 0; 
                            Num_Cut = 1; 
                        end
                        h = imfreehand(gca);
                        position = wait(h);
                        x = position(:, 1);
                        y = position(:, 2);
                        RAM = Connect_Points(RAM, x, y, 1, 1);
                        RAM = imfill(RAM, 'holes'); 
                        
                        if Num_Cut == 1 
                            close(f1); 
                        else 
                            close(f2); 
                        end
                        
                        Color = zeros([row, col, 3], 'uint8');
                        Color(:, :, 1) = OriColor(:, :, 1).*uint8(~RAM).*uint8(GhostCell ~= 0);
                        Color(:, :, 2) = OriColor(:, :, 2).*uint8(~RAM).*uint8(GhostCell ~= 0);
                        Color(:, :, 3) = OriColor(:, :, 3).*uint8(~RAM).*uint8(GhostNuc ~= 0); 
                        
                        f2 = figure; 
                        imshow(Color)
                        set(gcf, 'Position', get(0, 'Screensize')); 
                        continue_cut_or_not = questdlg('Are you satisfied with the cutting?', 'Cutting', 'Yes', 'No', 'Start Over', 'Yes');
                        switch continue_cut_or_not
                            case 'Yes'
                                If_Cutting = 0;
                                % We need to finalize the cutting results: 
                                GhostNuc = GhostNuc.*uint8(~RAM);
                                GhostCell = GhostCell.*uint8(~RAM); 
                                GhostBoundary = GhostBoundary.*uint8(~RAM); 
                                close(f2); 
                            case 'No' 
                                % 'No' does not means you did a wrong 
                                % cutting or what, which is 'start over'. 
                                % Choosing this means you want to do more
                                % cutting rather than a completely new one.
                                If_Cutting = 1; 
                            case 'Start Over'
                                If_Cutting = 1;
                                If_Start_Over_Cut = 1; 
                                close(f2); 
                                Color = zeros([row, col, 3], 'uint8');
                                Color(:, :, 1) = OriColor(:, :, 1).*uint8(LabledCells ~= 0);
                                Color(:, :, 2) = OriColor(:, :, 2).*uint8(LabledCells ~= 0);
                                Color(:, :, 3) = OriColor(:, :, 3).*uint8(LabledNuclei ~= 0);
                                if If_Boundaries_Adjusted == 1
                                    % This means we need to adjust the boundaries to be
                                    % displayed.
                                    Color(:, :, 1) = Color(:, :, 1) + SaveNewBoundaries;
                                end
                                f1 = figure;
                                imshow(Color) 
                                set(gcf, 'Position', get(0, 'Screensize')); 
                        end
                    end 
                    % Modify the boundary accordingly
                    CellIdx = unique(GhostCell(RAM)); 
                    CellIdx = CellIdx'; 
                    CellIdx(CellIdx == 0) = []; 
                    if ~isempty(CellIdx)
                        for ii = CellIdx
                            RAM2 = zeros([row, col], 'uint8');
                            RAM2(GhostCell == ii) = 1;
                            RAM2 = RAM2 ~= 0; 
                            ThisBoundary = bwboundaries(RAM2);
                            Num_Boundary = length(ThisBoundary);
                            Boundary_Length = zeros(1, Num_Boundary);
                            for jj = 1: Num_Boundary
                                Boundary_Length(jj) = length(ThisBoundary{jj});
                            end
                            ThisBoundary = ThisBoundary{Boundary_Length == max(Boundary_Length)};
                            for jj = 1:length(ThisBoundary(:, 1))
                                GhostBoundary(ThisBoundary(jj,1), ThisBoundary(jj,2)) = 255;
                            end
                        end
                    end
                    
            end
%% After either a 'Remove', 'Adjust' or 'Cut' step, do a visual inspection again.
            % Note (March 15, 2016)
            % In the old version, we kept the original boundaries and only
            % adds new boundaries, which is confusing for some cases, esp.
            % when boundaries were adjusted. 
            % The old version is commented out as follows: 
% %             Color = zeros([row, col, 3], 'uint8');
% %             Color(:, :, 1) = OriColor(:, :, 1).*uint8(GhostCell ~= 0);
% %             Color(:, :, 2) = OriColor(:, :, 2).*uint8(GhostCell ~= 0);
% %             Color(:, :, 3) = OriColor(:, :, 3).*uint8(GhostNuc ~= 0); 
% %             if If_Boundaries_Adjusted == 1  
% %                 % This means we need to adjust the boundaries to be
% %                 % displayed. 
% %                 Color(:, :, 1) = Color(:, :, 1) + SaveNewBoundaries; 
% %             end
            % Alternatively, we can regenerate the boundaries of every cell 
            % for every visual inspection: 
            % The shortcoming of this option is the slow speed
            % So rather than going over all cells each time, we record
            % which cells are changed in the prvious operations and only
            % regenerate the boundaries of these cells: 
                
            Color(:, :, 1) = GhostBoundary;
            Color(:, :, 2) = OriColor(:, :, 2).*uint8(GhostCell ~= 0);
            Color(:, :, 3) = OriColor(:, :, 3).*uint8(GhostNuc ~= 0); 
            

            f1 = figure; 
            imshow(Color)
            set(gcf, 'Position', get(0, 'Screensize')); 
            continue_or_not = questdlg('Are you satisfied with the operation?', 'Cutting', 'Yes', 'No', 'Start Over', 'Yes');
            switch continue_or_not
                case 'Yes'
                    option_control = 1; 
                    LabledNuclei = GhostNuc;
                    LabledCells = GhostCell; 
                    WorkingOutlines = GhostBoundary; 
                case 'No'
                    option_control = 1; 
                    close(f1); 
                    Color = zeros([row, col, 3], 'uint8');
                    Color(:, :, 1) = WorkingOutlines;
                    Color(:, :, 2) = OriColor(:, :, 2).*uint8(LabledCells ~= 0);
                    Color(:, :, 3) = OriColor(:, :, 3).*uint8(LabledNuclei ~= 0); 
                    f1 = figure;
                    imshow(Color)
                    set(gcf, 'Position', get(0, 'Screensize')); 
                case 'Start Over'
                    option_control = 1;
                    If_Start_Over_All = 1;
                    close(f1); 
            end
        case 'No'
            option_control = 0; 
            close(f1); 
    end 
end
MaskNuc = LabledNuclei; 
MaskCell = LabledCells; 
end % end of function 
