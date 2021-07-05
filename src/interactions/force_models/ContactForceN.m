%% ContactForceN (Normal Contact Force) class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef ContactForceN < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        VISCOELASTIC_LINEAR = uint8(1);
        
        % Types of stiffness formulation
        NONE    = uint8(1);
        TIME    = uint8(2);
        OVERLAP = uint8(3);
        ENERGY  = uint8(4);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of model
        
        % Contact parameters
        restitution double = double.empty;   % normal coefficient of restitution
        
        % Force results
        total_force double = double.empty;   % resulting force vector
    end
    
    %% Constructor method
    methods
        function this = ContactForceN(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactForceN_ViscoElasticLinear;
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