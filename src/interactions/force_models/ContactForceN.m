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
        VISCOELASTIC_LINEAR    = uint8(1);
        VISCOELASTIC_NONLINEAR = uint8(2);
        ELASTOPLASTIC_LINEAR   = uint8(3);
        
        % Types of linear stiffness formulation
        NONE    = uint8(1);
        TIME    = uint8(2);
        OVERLAP = uint8(3);
        ENERGY  = uint8(4);
        
        % Types of nonlinear damping formulation
        TTI = uint8(1);
        KK  = uint8(2);
        
        % Types of elastoplastic unloading stiffness formulation
        CONSTANT = uint8(1);
        VARIABLE = uint8(2);
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