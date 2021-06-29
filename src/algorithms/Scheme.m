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
        FOWARD_EULER = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type int8 = uint8.empty;   % flag for type of scheme
    end
    
    %% Constructor method
    methods
        function this = Scheme(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Search_FowardEuler;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end