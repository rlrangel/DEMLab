%% ContactForceN_ViscoElasticLinear class
%
%% Description
%
%% Implementation
%
classdef ContactForceN_ViscoElasticLinear < ContactForceN
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        stiff_formula   int8    = uint8.empty;     % flag for type of stiffness formulation
        remove_cohesion logical = logical.empty;   % flag for removing artificial cohesion
    end
    
    %% Constructor method
    methods
        function this = ContactForceN_ViscoElasticLinear()
            this = this@ContactForceN(ContactForceN.VISCOELASTIC_LINEAR);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.stiff_formula   = this.ENERGY;
            this.remove_cohesion = true;
        end
    end
end