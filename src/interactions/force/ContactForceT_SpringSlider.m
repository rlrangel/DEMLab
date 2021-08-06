%% ContactForceT_SpringSlider class
%
%% Description
%
% This is a sub-class of the <contactforcet.html ContactForceT> class for
% the implementation of the *Spring-Slider* tangent contact force model.
%
% This model assumes that the tangent contact force has an elastic component
% $F_{t}^{e}$, provided by a linear spring, and a friction component
% $F_{t}^{f}$, provided by a slider, which limits the total force according
% to Coulomb law. 
%
% $$\left \{ F_{t} \right \} = min(F_{t}^{e},F_{t}^{f})(-\hat{t})$$
%
% $$F_{t}^{e} = K_{t} \delta_{t}$$
%
% $$F_{t}^{f} = \mu \left | F_{n} \right |$$
%
% The tangent stiffness coefficient $K_{t}$ can be computed as a function
% of the normal stiffness coefficient $K_{n}$ and the effective Poisson
% ratio $\nu_{eff}$:
%
% $$K_{t} = \frac{1-\nu_{eff}}{1-\frac{\nu_{eff}}{2}}K_{n}$$
%
% The friction coefficient $\mu$ must be provided.
%
% *Notation*:
%
% $\hat{t}$: Tangent direction between elements
%
% $\delta_{t}$: Tangent overlap
%
% $\dot{\delta_{t}}$: Time rate of change of tangent overlap
%
% $F_{n}$: Normal contact force vector
%
% *References*:
%
% * <https://doi.org/10.1680/geot.1979.29.1.47
% P.A. Cundall and O.D.L. Strack.
% A discrete numerical model for granular assemblies, _Geotechnique_, 29:47-65, 1979>
% (proposal).
%
% * <https://doi.org/10.1115/1.4009973
% R.D. Mindlin.
% Compliance of elastic bodies in contact, _J. Appl. Mech._, 16(3):259-268, 1949>
% (stiffness coefficient formula).
%
classdef ContactForceT_SpringSlider < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        auto_stiff logical = logical.empty;   % flag for computing stiffness coefficient automatically
        
        % Contact parameters
        stiff double = double.empty;   % stiffness coefficient
        fric  double = double.empty;   % friction coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_SpringSlider()
            this = this@ContactForceT(ContactForceT.SPRING_SLIDER);
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
                if (~isempty(int.cforcen))
                    this.stiff = (1-int.eff_poisson)/(1-int.eff_poisson/2) * int.cforcen.stiff;
                else
                    this.stiff = 0;
                end
            end
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (elastic and friction contributions)
            fe = this.stiff * int.kinemat.ovlp_t;
            if (~isempty(int.cforcen))
                ff = this.fric * norm(int.cforcen.total_force);
            else
                ff = 0;
            end
            
            % Limit elastic force by Coulomb law
            f = min(abs(fe),abs(ff));
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end