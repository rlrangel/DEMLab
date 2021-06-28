%% Sink class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Sink < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of sink shapes
        RECTANGLE = 1;
        CIRCLE    = 2;
        POLYGON   = 3;
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type = 0;   % flag for type of sink shape
    end
    
    %% Constructor method
    methods
        function this = Sink(type)
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