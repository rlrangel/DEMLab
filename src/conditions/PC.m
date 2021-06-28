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
        UNIFORM     = uint8(1);
        LINEAR      = uint8(2);
        OSCILLATORY = uint8(3);
        TABLE       = uint8(4);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type uint8  = uint8.empty;   % flag for type of prescribed condition
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