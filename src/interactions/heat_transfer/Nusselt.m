%% Nusselt class
%
%% Description
%
% This is a handle super-class for the definition of models for the
% computation of the Nusselt number.
%
% The Nusselt number is used for estimating the convective coefficient when
% calculating the thermal convection between particles and the
% surrounding fluid.
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <Nusselt_Sphere_RanzMarshall.html Nusselt_Sphere_RanzMarshall>
% * <Nusselt_Sphere_Whitaker.html Nusselt_Sphere_Whitaker>
%
classdef Nusselt < handle
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        SPHERE_RANZ_MARSHALL = uint8(1);
        SPHERE_WHITAKER      = uint8(2);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of model
    end
    
    %% Constructor method
    methods
        function this = Nusselt(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        Nu = getValue(this,particle,drv);
    end
end