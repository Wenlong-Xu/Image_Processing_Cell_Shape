%% Function to Create Vector of Data Contained in Structure 
%  October 26, 2015 
%  Wenlong Xu 
%  Prasad Group 
%  Colorado State Univ. 
%  ------------------------------------------------------------------------
function OUT = Struct2Vec(Props, STR)
%OUT = Struct2vec(Props, S) creates a new column vector or matrix OUT from 
%the field as specified by string STR in the structure array Props. 
if ~ischar(STR)
    error('Wrong Input of Type String. \n'); 
end

eval(['Sample = Props(1).', STR, ';']); 
% Proceed only if the requested field is a vector: 
if ~isvector(Sample) 
    error('Requested field not supported. \n'); 
end
Num_regions = length(Props); 
Num = length(Sample); 
OUT = zeros(Num_regions, Num); 
for ii = 1:Num_regions 
    eval(['OUT(', num2str(ii), ', :) = Props(', num2str(ii), ').', STR, ';']); 
end

end % end of function 