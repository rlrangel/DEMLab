%% ContactForceT_SDSLinear class
%
%% Description
%
% This is a sub-class of the <contactforcet.html ContactForceT> class for
% the implementation of the *Linear Spring-Dashpot-Slider* tangent contact
% force model.
%
% This model assumes that the tangent contact force has an elastic component
% $F_{t}^{e}$, provided by a linear spring, a viscous component
% $F_{t}^{v}$, provided by a linear dashpot, and a friction component
% $F_{t}^{f}$, provided by a slider, which limits the total force according
% to Coulomb law. 
%
% $$\left \{ F_{t} \right \} = min(\left | F_{t}^{e}+F_{t}^{v} \right |,F_{t}^{f})(-\hat{t})$$
%
% $$F_{t}^{e} = K_{t} \delta_{t}$$
%
% $$F_{t}^{v} = \eta_{t} \dot{\delta_{t}}$$
%
% $$F_{t}^{f} = \mu \left | F_{n} \right |$$
%
% The tangent stiffness coefficient $K_{t}$ can be computed as a function
% of the normal stiffness coefficient $K_{n}$ and the effective Poisson
% ratio $\nu_{eff}$:
%
% $$K_{t} = \frac{1-\nu_{eff}}{1-\frac{\nu_{eff}}{2}}K_{n}$$
%
% The tangent damping coefficient $\eta_{t}$ can be computes as:
%
% * If the tangent coefficient of restitution is zero ($e=0$):
%
% $$\eta_{t} = 2\sqrt{\frac{2m_{eff}K_{t}}{7}}$$
%
% * If the tangent coefficient of restitution is different than zero
% ($e \not\equiv 0$):
%
% $$\eta_{t} = -2ln(e)\sqrt{\frac{2m_{eff}K_{t}}{7(ln(e)^{2} + \pi^{2})}}$$
%
% The tangent coefficient of restitution and the friction coefficient $\mu$
% must be provided.
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
% $m_{eff}$: Effective mass
%
% *References*:
%
% * <https://doi.org/10.1115/1.4009973
% R.D. Mindlin.
% Compliance of elastic bodies in contact, _J. Appl. Mech._, 16(3):259-268, 1949>
% (stiffness coefficient formula)
%
% * <https://doi.org/10.1016/j.ces.2006.08.014
% N.G. Deen, M. Van Sint Annaland, M.A. Van der Hoef and J.A.M. Kuipers.
% Review of discrete particle modeling of fluidized beds, _Chem. Eng. Sci._, 62(1-2):28-44, 2007>
% (damping coefficient formula)
%
classdef ContactForceT_SDSLinear < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        auto_stiff logical = logical.empty;   % flag for computing stiffness coefficient automatically
        auto_damp  logical = logical.empty;   % flag for computing damping coefficient automatically
        
        % Contact parameters
        stiff double = double.empty;   % stiffness coefficient
        damp  double = double.empty;   % damping coefficient
        fric  double = double.empty;   % friction coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_SDSLinear()
            this = this@ContactForceT(ContactForceT.SDS_LINEAR);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            this.auto_stiff = true;
            this.auto_damp  = false;
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
            if (this.auto_damp)
                if (this.restitution == 0)
                    this.damp = 2 * sqrt(2 * int.eff_mass * this.stiff / 7);
                else
                    lnrest = log(this.restitution);
                    this.damp = -2 * lnrest * sqrt(2 * int.eff_mass * this.stiff / 7) / sqrt(lnrest^2 + pi^2);
                end
            end
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (viscoelastic and friction contributions)
            fe = this.stiff * int.kinemat.ovlp_t;
            fv = this.damp  * int.kinemat.vel_t;
            if (~isempty(int.cforcen))
                ff = this.fric * norm(int.cforcen.total_force);
            else
                ff = 0;
            end
            
            % Limit viscoelastic force by Coulomb law
            f = min(abs(fe+fv),abs(ff));
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end