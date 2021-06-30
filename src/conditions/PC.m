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
        % Types of prescribed condition variation
        UNIFORM     = uint8(1);
        LINEAR      = uint8(2);
        OSCILLATORY = uint8(3);
        TABLE       = uint8(4);
        
        % Types of conditions
        FORCE     = uint8(1);
        TORQUE    = uint8(2);
        HEAT_FLUX = uint8(3);
        HEAT_RATE = uint8(3);
        
        % Types of interpolation methods
        INTERP_LINEAR = uint8(1);
        INTERP_MAKIMA = uint8(2);
        INTERP_CUBIC  = uint8(3);
        INTERP_PCHIP  = uint8(4);
        INTERP_SPLINE = uint8(5);
        % https://uk.mathworks.com/help/matlab/ref/interp1.html#btwp6lt-1-extrapolation
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type      uint8  = uint8.empty;    % flag for type of prescribed condition variation
        condition uint8  = uint8.empty;    % flag for type of condition
        interval  double = double.empty;   % time interval of activation
    end
    
    %% Constructor method
    methods
        function this = PC(type,condition)
            if (nargin > 0)
                this.type = type;
                if (nargin == 2)
                    this.condition = condition;
                end
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = PC_Uniform;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        applyDefaultProps(this);
        
        %------------------------------------------------------------------
        val = getValue(this,time);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function is = isActive(this,time)
            is = isempty(this.interval) || (time > min(this.interval) && time < max(this.interval));
        end
    end
end