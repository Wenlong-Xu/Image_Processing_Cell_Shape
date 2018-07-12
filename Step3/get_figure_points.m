function [X Y cancelled] = get_figure_points(axes_handle,ls_options)
% GET_FIGURE_REGION  Get x and y values of mouse clicks on a figure
%   [ X Y ] = GET_FIGURE_POINTS()
%   [ X Y ] = GET_FIGURE_POINTS(axes_handle)
%   [ X Y ] = GET_FIGURE_POINTS(axes_handle,ls_options)
%   [ X Y cancelled ] = GET_FIGURE_POINTS(...)
%   
%   This function gets the current axes and allows the user to click the
%   figure to create a polygon whose vertices are returned in the X and Y
%   vectors. If there is no current axes, an exception is thrown.
%
%   With each left mouse-click, a point is added to the polygon and
%   displayed on the figure. When all desired points have been chosen, the
%   ENTER key completes the selection, in which case cancelled returns
%   false. If 'x' or ESC is pressed, the tool aborts, X and Y return [] and
%   cancelled returns true;
%
%   Inputs:
%     axes_handle:
%       If axes handle axes_handle is specified, that axes is used instead
%       of the current axes. If axes_handle is not a valid axes handle, an
%       exception is thrown.
%     ls_options:
%       ls_options is an optional cell array of <a href="V:\Matlab2011b\help/techdoc/ref/lineseriesproperties.html">lineseries properties</a>
%       in the format of {'name1', argument1, 'name2', argument2, etc...},
%       to change the appearance of the line plotted showing the chosen
%       points. To specify ls_options but still use the current axes, just
%       set axes_handle to gca.
%
%   Ouputs:
%     X, Y:
%       Vectors of points where the mouse was clicked
%     cancelled:
%       Boolean returning whether or not the tool was cancelled
%       
%   Misc notes:
%   - None of the outputs are required.
%   - If axes_handle is specified, the axes that were current before this
%     tool was run are made current again.
%   - The if the hold state for the current axes was false before this tool
%     runs, it is restored to that state.

%% Prep
% Assume the tool has not been canceled until it has.
cancelled = false;

%%% prepare axes
current_axes = [];
if exist('axes_handle','var')
    % check to make sure axes_handle is a valid axes handle
    if ~isscalar(axes_handle) || ~ishandle(axes_handle) || ~strcmp('axes',get(axes_handle,'Type'))
        error('get_figure_points:invalid_axes_handle','The input axes_handle must be a valid axes handle.');
    end
    % save current axes
    if ~isempty(get(0,'CurrentFigure')) && ~isempty(get(gcf,'CurrentAxes'))
        current_axes = gca;
    end
else
    % if no axes is provided, see if the current figure and current axes
    % exist, and if so, set axes_handle to the current axes.
    if ~isempty(get(0,'CurrentFigure')) && ~isempty(get(gcf,'CurrentAxes'))
        axes_handle = gca;
    else
        error('get_figure_points:no_current_axes','There is no set of current axes to work with');
    end
end

% Make axes_handle current
axes(axes_handle);

% save and set the hold state
held = ishold;
if ~ishold
    hold on;
end

%%% process ls_options
if exist('ls_options','var')
    if ~iscell(ls_options)
        error('get_figure_points:invalid_ls_options','The input ls_options must be a cell array of lineseries properties.');
    end
else
    ls_options = {};
end
%%% set default line options
if ~any(strcmp(ls_options,'LineWidth'))
    ls_options = [ls_options {'LineWidth', 2}];
end
if ~any(strcmp(ls_options,'Color'))
    ls_options = [ls_options {'Color', 'red'}];
end
if ~any(strcmp(ls_options,'Marker'))
    ls_options = [ls_options {'Marker', '.'}];
end
if ~any(strcmp(ls_options,'LineStyle'))
    ls_options = [ls_options {'LineStyle', '-'}];
end



%% Get the points
%%% preallocate - not a big deal and if we go over 256 it's ok.
i = 0;
X = NaN(1,256);
Y = NaN(1,256);
%%% get the points
while 1
    %get a mouse click and its coordinates on the image
    [x,y,b] = ginputc(1, 'Color', 'r', 'LineWidth', 1);
    if isempty(b)
        % ENTER was pressed
        break
    elseif b == 27 || b == 120
        % ESC or 'x' was pressed. Cancel.
        cancelled = true;
        break
    elseif b == 1
        %%% left mouse button was pressed. Save x and y and plot X and Y as
        %%% a line.
        i = i + 1;
        X(i) = x;
        Y(i) = y;
        % remove the polygon before replacing it.
        if exist('h_poly','var')
            delete(h_poly);
        end
        h_poly = plot(axes_handle,X,Y,ls_options{:});
    else
        % do nothing. Invalid key or button pressed
    end
end

%%% remove extra preallocated X and Y values.
if i == 0
    X = [];
    Y = [];
elseif i < numel(X)
    X(i + 1:end) = [];
    Y(i + 1:end) = [];
end

%%% If cancelled, set output to empty
if cancelled
    X = [];
    Y = [];
end

%% Cleanup
%%% remove polygon
delete(h_poly);

% Restore hold state and current axes
if ~held
    hold off
end
if ~isempty(current_axes)
    axes(current_axes);
end