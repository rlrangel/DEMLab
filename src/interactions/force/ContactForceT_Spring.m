%% ContactForceT_Spring class
%
%% Description
%
% This is a sub-class of the <contactforcet.html ContactForceT> class for
% the implementation of the *Simple Spring* tangent contact force model.
%
% This model assumes that the tangent contact force has only an elastic
% component $F_{t}^{e}$, provided by a linear spring.
%
% $$\left \{ F_{t} \right \} = -F_{t}^{e}\hat{t}$$
%
% $$F_{t}^{e} = K_{t} \delta_{t}$$
%
% The tangent stiffness coefficient $K_{t}$ can be computed as a function
% of the normal stiffness coefficient $K_{n}$ and the effective Poisson
% ratio $\nu_{eff}$:
%
% $$K_{t} = \frac{1-\nu_{eff}}{1-\frac{\nu_{eff}}{2}}K_{n}$$
%
% *Notation*:
%
% $\hat{t}$: Tangent direction between elements
%
% $\delta_{t}$: Tangent overlap
%
% *References*:
%
% * <https://doi.org/10.1115/1.4009973
% R.D. Mindlin.
% Compliance of elastic bodies in contact, _J. Appl. Mech._, 16(3):259-268, 1949>
% (stiffness coefficient formula).
%
classdef ContactForceT_Spring < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        auto_stiff logical = logical.empty;   % flag for computing stiffness coefficient automatically
        
        % Contact parameters
        stiff double = double.empty;   % stiffness coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Spring()
            this = this@ContactForceT(ContactForceT.SPRING);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            this.auto_stiff = true;
        end
        
        %------------------------------------------------------------------
        function this = setParameters(this,int)
            if (this.auto_stiff)
                this.stiff = (1-int.eff_poisson)/(1-int.eff_poisson/2) * int.cforcen.stiff;
            end
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (elastic contribution only)
            f = this.stiff * int.kinemat.ovlp_t;
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end