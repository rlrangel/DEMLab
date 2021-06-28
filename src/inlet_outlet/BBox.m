%% BBox class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef BBox < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of bounding box shapes
        RECTANGLE = 1;
        CIRCLE    = 2;
        POLYGON   = 3;
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type     = 0;    % flag for type of bounding box shape
        interval = [];   % time interval of activation
    end
    
    %% Constructor method
    methods
        function this = BBox(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end