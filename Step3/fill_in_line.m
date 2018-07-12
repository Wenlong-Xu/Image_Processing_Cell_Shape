function [X, Y]=fill_in_line(X1, Y1, X2, Y2)
%% This function find the all pixels positions between two inputed points 
%  NOTE: There are redundency in the output!  
X1 = floor(X1); 
Y1 = floor(Y1); 
X2 = ceil(X2); 
Y2 = ceil(Y2); 
if X1 ~= X2 && Y1 ~= Y2
    
    Slope = (Y2 - Y1)/(X2 - X1);
    Intercept = Y2 - Slope*X2; 
    xx = X1:sign(X2-X1)/1000:X2; 
    yy = Slope.*xx + Intercept; 
    xx1 = ceil(xx); 
    xx2 = floor(xx); 
    yy1 = ceil(yy); 
    yy2 = floor(yy);
    X = [xx1, xx2];
    Y = [yy1, yy2];
elseif X1 == X2 || Y1 ~= Y2
    Y = Y1:sign(Y2-Y1):Y2; 
    X = X1 .* ones(size(Y)); 
elseif X1 ~= X2 || Y1 == Y2
    X = X1:sign(X2-X1):X2;
    Y = Y1 .* ones(size(X)); 
elseif X1 == X2 || Y1 == Y2
    X = X1; 
    Y = Y1; 
else 
    error('Something is Wrong here!')
end