%% PC (Prescribed Condition) class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef PC < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of scheme
        UNIFORM     = 1;
        LINEAR      = 2;
        OSCILLATORY = 3;
        TABLE       = 4;
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type = 0;   % flag for type of prescribed condition
    end
    
    %% Constructor method
    methods
        function this = PC(type)
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