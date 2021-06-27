%% Wall class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Wall < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of wall
        LINE2D = 1;
        CIRCLE = 2;
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type = 0;   % flag for type of wall
        id   = 0;   % identification number
    end
    
    %% Constructor method
    methods
        function this = Wall(type)
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