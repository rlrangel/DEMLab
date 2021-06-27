%% BBox_Circle class
%
%% Description
%
%% Implementation
%
classdef BBox_Circle < BBox
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = BBox_Circle()
            this = this@BBox(BBox.CIRCLE);
        end
    end
    
    %% Public methods
    methods
        
    end
end