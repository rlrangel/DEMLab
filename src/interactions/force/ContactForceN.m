%% ContactForceN (Normal Contact Force) class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of models
% for the normal contact force between elements.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <contactforcen_viscoelasticlinear.html ContactForceN_ViscoElasticLinear> (default)
% * <contactforcen_viscoelasticnonlinear.html ContactForceN_ViscoElasticNonlinear>
% * <contactforcen_elastoplasticlinear.html ContactForceN_ElastoPlasticLinear>
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
        LH  = uint8(3);
        
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
        stiff       double = double.empty;   % spring stiffness coefficient
        damp        double = double.empty;   % damping coefficient
        
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
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactForceN_ViscoElasticLinear;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        this = setDefaultProps(this);
        
        %------------------------------------------------------------------
        this = setParameters(this,interact);
        
        %------------------------------------------------------------------
        this = evalForce(this,interact);
    end
end