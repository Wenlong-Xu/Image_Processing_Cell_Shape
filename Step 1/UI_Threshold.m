%% Function to Get the Mask from Digital Images
%  Wenlong Xu
%  June 2, 2017 
%  ------------------------------------------------------------------------
function f1 = UI_Threshold(originalImage)
global Threshold
% Calculate the upper limit of the slider as 99% saturation intensity. 
% Becuase at least 1% of the image should be cells. 
[row, col] = size(originalImage); 
Image_Max = double(intmax(class(originalImage))); 
counts = hist(reshape(originalImage, [1, row*col]), 0:1:Image_Max); 
Slider_Max = find((cumsum(counts)./(row*col)) > 0.99, 1, 'first'); 
Slider_Max = Slider_Max/Image_Max; 
Threshold = Slider_Max;  

Mask = im2bw(originalImage, Threshold); 
Mask = cast(Mask, class(originalImage)); 
Disp = repmat(Mask, [1, 1, 3]);
Out  = Disp.*repmat(originalImage, [1, 1, 3]);
R_Mask = ~Mask; 
R_Mask = cast(R_Mask, class(originalImage)); 
R_Mask = R_Mask.*intmax(class(originalImage)); 
Disp2 = cat(3, R_Mask, zeros(size(R_Mask)));
Disp2 = cat(3, Disp2, zeros(size(R_Mask)));
Out = Out + Disp2; 

f1 = figure; 
set(gcf, 'Position', get(0, 'ScreenSize'))
ax = axes('Parent',f1,'position',[0.1, 0.25, 0.8, 0.65]); 
%                                 left  bottom width height
set(ax, 'Units', 'Pixels'); 
AXPos = get(ax, 'Position'); 
imshow(Out); 
SPos = [AXPos(1)+floor(AXPos(3)/4), floor(AXPos(2)*0.66), floor(AXPos(3)/2), 20]; 
b = uicontrol('Parent',f1,'Style','slider','Position',SPos, ...'Units', 'normalized',
              'value', Threshold, 'min', 0, 'max', Slider_Max, 'SliderStep', [1/Image_Max, 1/Image_Max]); 

bgcolor = f1.Color;
bl1 = uicontrol('Parent',f1,'Style','text','Position',[SPos(1)-30,SPos(2),20,20],...
                'String','0','BackgroundColor',bgcolor, 'FontSize', 10, 'FontWeight', 'Bold');
bl2 = uicontrol('Parent',f1,'Style','text','Position',[SPos(1)+SPos(3)+20,SPos(2),60,20],...
                'String',num2str(Slider_Max),'BackgroundColor',bgcolor, 'FontSize', 10, 'FontWeight', 'Bold');
bl3 = uicontrol('Parent',f1,'Style','text','Position',[AXPos(1)+floor(AXPos(3)/2)-50, SPos(2)+20, 100, 20],...
                'String','Threshold','BackgroundColor',bgcolor, 'FontSize', 10, 'FontWeight', 'Bold', 'HorizontalAlignment', 'center');   
            
b.Callback = @(es, ep) slider1_callback(originalImage, es.Value);

end

function slider1_callback(IN, Th1)
evalin('base', ['Threshold = ', sprintf('%f', Th1), ';']); 

Mask = im2bw(IN, Th1); 
Mask = cast(Mask, class(IN)); 
Disp = repmat(Mask, [1, 1, 3]);
Out  = Disp.*repmat(IN, [1, 1, 3]);
R_Mask = ~Mask; 
R_Mask = cast(R_Mask, class(IN)); 
R_Mask = R_Mask.*intmax(class(IN)); 
Disp2 = cat(3, R_Mask, zeros(size(R_Mask)));
Disp2 = cat(3, Disp2, zeros(size(R_Mask)));
Out = Out + Disp2; 
imshow(Out)
end