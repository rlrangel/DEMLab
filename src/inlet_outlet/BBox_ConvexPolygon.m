%% BBox_ConvexPolygon class
%
%% Description
%
%% Implementation
%
classdef BBox_ConvexPolygon < BBox
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = BBox_ConvexPolygon()
            this = this@BBox(BBox.CONVEX_POLYGON);
        end
    end
    
    %% Public methods
    methods
        
    end
end