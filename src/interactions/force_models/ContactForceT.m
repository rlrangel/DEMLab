%% ContactForceT (Tangential Contact Force) class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef ContactForceT < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        SLIDER                = uint8(1);
        SPRING                = uint8(2);
        DASHPOT               = uint8(3);
        SPRING_SLIDER         = uint8(4);
        DASHPOT_SLIDER        = uint8(5);
        SPRING_DASHPOT_SLIDER = uint8(6);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of model
        
        % Contact parameters
        restitution double = double.empty;   % tangent coefficient of restitution
        
        % Force results
        total_force double = double.empty;   % resulting force vector
    end
    
    %% Constructor method
    methods
        function this = ContactForceT(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactForceT_Spring;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        this = setDefaultProps(this);
        
        %------------------------------------------------------------------
        this = setParameters(this,interact);
        
        %------------------------------------------------------------------
        this = evalForce(this,interact);
    end
    
    %% Public methods
    methods
        
    end
end