%% Scheme class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Scheme < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of scheme
        FOWARD_EULER = 1;
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type = 0;   % flag for type of scheme
    end
    
    %% Constructor method
    methods
        function this = Scheme(type)
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