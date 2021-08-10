%% ContactForceT_SDSNonlinear class
%
%% Description
%
% This is a sub-class of the <contactforcet.html ContactForceT> class for
% the implementation of the *Nonlinear Spring-Dashpot-Slider* tangent
% contact force model.
%
% This model assumes that the tangent contact force has an elastic component
% $F_{t}^{e}$, provided by a spring, a viscous component $F_{t}^{v}$,
% provided by a dashpot, and a friction component $F_{t}^{f}$, provided by
% a slider, which limits the total force according to Coulomb law. 
%
% $$\left \{ F_{t} \right \} = min\left ( \left | F_{t}^{e}+F_{t}^{v} \right |,F_{t}^{f} \right ) \{-\hat{t}\}$$
%
% $$F_{t}^{f} = \mu \left | F_{n} \right |$$
%
% The friction coefficient $\mu$ must be provided.
%
% The elastic and viscous components can be camputed by different
% formulations:
%
% * *DD (Di Renzo & Di Maio)*:
%
% $$F_{t}^{e} = \frac{16}{3} G_{eff} \sqrt{R_{eff} \delta_{n}} \delta_{t}$$
%
% $$F_{t}^{v} = 0$$
%
% * *LTH (Langston, Tuzun, Heyes)*:
%
% $$F_{t}^{e} = \mu \left | F_{n} \right | \left ( 1 - \left ( 1 - \frac{min(\left | \delta_{t} \right |,\delta_{t}^{max})}{\delta_{t}^{max}}) \right )^{3/2} \right )$$
%
% $$F_{t}^{v} = \eta_{t} \left ( \frac{6m_{eff} \mu \left | F_{n} \right |}{\delta_{t}^{max}} \sqrt{1 - \frac{min(\left | \delta_{t} \right |,\delta_{t}^{max})}{\delta_{t}^{max}}} \right )^{1/2} \dot{\delta_{t}}$$
%
% The tangent damping coefficient $\eta_{t}$ must be provided.
%
% * *ZZY (Zheng, Zhu, Yu)*:
%
% $$F_{t}^{e} = \mu \left | F_{n} \right | \left ( 1 - \left ( 1 - \frac{min(\left | \delta_{t} \right |,\delta_{t}^{max})}{\delta_{t}^{max}}) \right )^{3/2} \right )$$
%
% $$F_{t}^{v} = \frac{\eta_{t}}{2G_{eff}\delta_{t}^{max}} \left ( 1 - \frac{0.4\eta_{t} \left | \dot{\delta_{t}} \right | }{2G_{eff}\delta_{t}^{max}} \right ) \left ( 1.5\mu \left | F_{n} \right | \sqrt{1 - \frac{min(\left | \delta_{t} \right |,\delta_{t}^{max})}{\delta_{t}^{max}}} \right ) \dot{\delta_{t}}$$
%
% The tangent damping coefficient $\eta_{t}$ must be provided.
%
% * *TTI (Tsuji, Tanaka, Ishida)*:
%
% $$F_{t}^{e} = \frac{\sqrt{2R_{eff}}E_{eff}}{(2-\nu_{eff})(1+\nu_{eff})} \sqrt{\delta_{n}} \delta_{t}$$
%
% $$F_{t}^{v} = \eta_{n} \dot{\delta_{t}}$$
%
% The tangent damping coefficient $\eta_{t}$ must be provided.
%
% *Notation*:
%
% $\hat{t}$: Tangent direction between elements
%
% $\delta_{n}$: Normal overlap
%
% $\delta_{t}$: Tangent overlap
%
% $\dot{\delta_{t}}$: Time rate of change of tangent overlap
%
% $F_{n}$: Normal contact force vector
%
% $m_{eff}$: Effective mass
%
% $R_{eff}$: Effective contact radius
%
% $E_{eff}$: Effective Young modulus
%
% $G_{eff}$: Effective shear modulus
%
% $\nu_{eff}$: Effective Poisson ratio
%
% $\delta_{t}^{max} = \mu \delta_{n} \frac{2-\nu_{eff}}{2(1-\nu_{eff})}$:
% Tangent overlap when sliding starts
%
% *References*:
%
% * <https://doi.org/10.1016/j.ces.2004.10.004
% A. Di Renzo and F.P. Di Maio.
% An improved integral non?linear model for the contact of particles in distinct element simulations, _Chem. Eng. Sci._, 60(5):1303-1312, 2005>
% (DD model)
%
% * <https://doi.org/10.1016/0009-2509(94)85095-X
% P.A. Langston, U. Tuzun and D.M.Heyes.
% Continuous potential discrete particle simulations of stress and velocity fields in hoppers: transition from fluid to granular flow, _Chem. Eng. Sci._, 49(8):1259-1275, 1994>
% (LTH model)
%
% * <https://doi.org/10.1016/j.powtec.2012.04.032
% Q.J. Zheng, H.P. Zhub and A.B. Yu.
% Finite element analysis of the contact forces between a viscoelastic sphere and rigid plane, _Powder Technol._, 226:130-142, 2012>
% (ZZY model)
%
% * <https://doi.org/10.1016/0032-5910(92)88030-L
% Y. Tsuji, T. Tanaka and T. Ishida.
% Lagrangian numerical simulation of plug flow of cohesionless particles in a horizontal pipe, _Powder Technol._, 71(3):239-250, 1992>
% (TTI model)
%
classdef ContactForceT_SDSNonlinear < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        formula uint8 = uint8.empty;   % flag for type of nonlinear formulation
        
        % Contact parameters
        stiff double = double.empty;   % stiffness coefficient
        damp  double = double.empty;   % damping coefficient
        fric  double = double.empty;   % friction coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_SDSNonlinear()
            this = this@ContactForceT(ContactForceT.SDS_NONLINEAR);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,int)
            if (this.formula == this.TTI && isempty(this.damp))
                if (~isempty(int.cforcen))
                    this.damp = int.cforcen.damp;
                else
                    this.damp = 0;
                end
            end
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (friction contribution)
            if (~isempty(int.cforcen))
                ff = this.fric * norm(int.cforcen.total_force);
            else
                ff = 0;
            end
            
            % Force modulus (viscoelastic contribution)
            switch this.formula
                case this.DD
                    this.stiff = 16 * int.eff_shear * sqrt(int.eff_radius * int.kinemat.ovlp_n) / 3;
                    f = this.stiff * int.kinemat.ovlp_t;
                case this.LTH
                    max_ovlp = this.fric * int.kinemat.ovlp_n * (2 - int.eff_poisson) / (2 - 2 * int.eff_poisson);
                    a  = 1 - min(abs(int.kinemat.ovlp_t),max_ovlp) / max_ovlp;
                    fe = ff * (1 - a^(3/2));
                    fv = this.damp * sqrt(6 * int.eff_mass * ff * sqrt(a) / max_ovlp) * int.kinemat.vel_t;
                    f  = fe + fv;
                case this.ZZY
                    max_ovlp = this.fric * int.kinemat.ovlp_n * (2 - int.eff_poisson) / (2 - 2 * int.eff_poisson);
                    a  = 1 - min(abs(int.kinemat.ovlp_t),max_ovlp) / max_ovlp;
                    fe = ff * (1 - a^(3/2));
                    fv = this.damp / (2 * int.eff_shear * max_ovlp) * (1 - 0.4 * this.damp * abs(int.kinemat.vel_t) / (2 * int.eff_shear * max_ovlp)) * (1.5 * ff * sqrt(a)) * int.kinemat.vel_t;
                    f  = fe + fv;
                case this.TTI
                    this.stiff = sqrt(2 * int.eff_radius) * int.eff_young * sqrt(int.kinemat.ovlp_n) / ((2 - int.eff_poisson) * (1 + int.eff_poisson));
                    fe = this.stiff * int.kinemat.ovlp_t;
                    fv = this.damp  * int.kinemat.vel_t;
                    f  = fe + fv;
            end
            
            % Limit viscoelastic force by Coulomb law
            f = min(abs(f),abs(ff));
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end