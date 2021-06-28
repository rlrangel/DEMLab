%% BBox_Rectangle class
%
%% Description
%
%% Implementation
%
classdef BBox_Rectangle < BBox
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        limit_min double = double.empty;   % coordinates of minimum limits (bottom-left corner)
        limit_max double = double.empty;   % coordinates of maximum limits (top-right corner)
    end
    
    %% Constructor method
    methods
        function this = BBox_Rectangle()
            this = this@BBox(BBox.RECTANGLE);
        end
    end
    
    %% Public methods
    methods
        
    end
end