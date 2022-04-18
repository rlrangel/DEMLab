%% Scheme class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of time
% integration schemes.
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <scheme_eulerforward.html Scheme_EulerForward> (default)
% * <scheme_eulermod.html Scheme_EulerMod>
% * <scheme_taylor2.html Scheme_Taylor2>
%
classdef Scheme < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of time integration scheme
        EULER_FORWARD  = uint8(1);
        EULER_MODIFIED = uint8(2);
        TAYLOR_2       = uint8(3);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type uint8 = uint8.empty;   % flag for type of time integration scheme
    end
    
    %% Constructor method
    methods
        function this = Scheme(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Scheme_EulerForward;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        updatePosition(this,particle,time_step);
        
        %------------------------------------------------------------------
        updateOrientation(this,particle,time_step);
        
        %------------------------------------------------------------------
        updateTemperature(this,particle);
    end
end