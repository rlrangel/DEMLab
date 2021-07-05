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
        EULER_FORWARD  = uint8(1);
        EULER_MODIFIED = uint8(2);
        TAYLOR_2       = uint8(3);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type uint8 = uint8.empty;   % flag for type of scheme
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
            defaultObject = Search_EulerForward;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        updatePosition(this,particle,time_step);
        
        %------------------------------------------------------------------
        updateOrientation(this,particle,time_step);
        
        %------------------------------------------------------------------
        updateTemperature(this,particle);
    end
    
    %% Public methods
    methods
        
    end
end