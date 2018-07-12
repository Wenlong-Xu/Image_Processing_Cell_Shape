%% Mark Lines out on an Image Based on Inputed Sequantial Points 
%  Wenlong Xu
%  July 14, 2014 
%  ------------------------------------------------------------------------
%% Introduction
%  This function connects the points indexed by pixel positions using 0 or
%  1 on input image via straight lines. 
%  ------------------------------------------------------------------------
%% Input & Output 
%  In  -- the input image needs marking (Binary Image)
%  Px  -- X pixel position for points needing connected 
%  Py  -- Y pixel position for points needing connected 
%  V   -- 0 or 1, the value used to mark out the lines
%  Mode-- 0 or 1, If line connected from the last point to the first point
%  Out -- the output image with connections made (Binary Image)
%  ------------------------------------------------------------------------
function Out = Connect_Points(In, Px, Py, V, Mode) 
    Last = length(Px); 
    for ii = 1:1:(Last-1)
        [LineX, LineY] = fill_in_line(Px(ii), Py(ii), Px(ii+1), Py(ii+1));
        for jj = 1:1:length(LineX)
            In(LineY(jj), LineX(jj)) = V;
        end
    end
    if Mode == 1
        [LineX, LineY] = fill_in_line(Px(Last), Py(Last), Px(1), Py(1)); 
        for jj = 1:1:length(LineX)
            In(LineY(jj), LineX(jj)) = V;
        end
    end
    Out = logical(In);
end