%% BBox_Polygon class
%
%% Description
%
%% Implementation
%
classdef BBox_Polygon < BBox
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        coord_x double = double.empty;   % vector of X coodinates of polygon points
        coord_y double = double.empty;   % vector of Y coodinates of polygon points
    end
    
    %% Constructor method
    methods
        function this = BBox_Polygon()
            this = this@BBox(BBox.POLYGON);
        end
    end
    
    %% Public methods
    methods
        
    end
end