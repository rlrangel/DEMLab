%% ContactForceN_ViscoElasticLinear class
%
%% Description
%
% This is a sub-class of the <ContactForceN.html ContactForceN> class for
% the implementation of the *Linear Visco-Elastic* normal contact force
% model.
%
% This model assumes that the normal contact force has an elastic
% $F_{n}^{e}$ and a viscous $F_{n}^{v}$ component, provided by a linear
% spring and dashpot, respectively.
%
% $$\left \{ F_{n} \right \} = (F_{n}^{e} + F_{n}^{v}) \{-\hat{n}\}$$
%
% $$F_{n}^{e} = K_{n} \delta_{n}$$
%
% $$F_{n}^{v} = \eta_{n} \dot{\delta_{n}}$$
%
% The stiffness coefficient $K_{n}$ can be computed by 3
% different formulas, if its value is not provided:
%
% * *Equivalent energy*:
%
% $$K_{n} = 1.053 \left ( \dot{\delta}_{n}^{0}R_{eff}E_{eff}^{2}\sqrt{m_{eff}} \right )^{2/5}$$
%
% * *Equivalent overlap*:
%
% $$K_{n} = 1.053 \left ( \dot{\delta}_{n}^{0}R_{eff}E_{eff}^{2}\sqrt{m_{eff}} \right )^{2/5} \left ( 1+\beta^{-2} \right )$$
%
% * *Equivalent time*:
%
% $$K_{n} = 1.198 \left ( \dot{\delta}_{n}^{0}R_{eff}E_{eff}^{2}\sqrt{m_{eff}} \right )^{2/5} \left ( exp \left ( -\frac{tg^{-1}(\beta)}{\beta} \right ) \right )^{2}$$
%
% The damping coefficient $\eta_{n}$ is computed with the following formula, if its value is not provided:
%
% $$\eta_{n} = \sqrt{\frac{4m_{eff}K_{n}}{1+\beta^{2}}}$$
%
% *Notation*:
%
% $\hat{n}$: Normal direction between elements
%
% $\delta_{n}$: Normal overlap
%
% $\dot{\delta_{n}}$: Time rate of change of normal overlap
%
% $\dot{\delta}_{n}^{0}$: Time rate of change of normal overlap at the impact moment
%
% $R_{eff}$: Effective contact radius
%
% $E_{eff}$: Effective Young modulus
%
% $m_{eff}$: Effective mass
%
% $\beta = \frac{\pi}{ln(e)}$, where _e_ is the normal coefficient of restitution
%
% *References*:
%
% * <https://doi.org/10.1680/geot.1979.29.1.47
% P.A. Cundall and O.D.L. Strack.
% A discrete numerical model for granular assemblies, _Geotechnique_, 29:47-65, 1979>
% (proposal)
%
% * <https://www.wiley.com/en-ai/Coupled+CFD+DEM+Modeling%3A+Formulation%2C+Implementation+and+Application+to+Multiphase+Flows-p-9781119005131
% H.R. Norouzi, R. Zarghami, R. Sotudeh-Gharebagh and N. Mostoufi.
% _Coupled CFD-DEM Modeling: Formulation, Implementation and Application to Multiphase Flows_, Wiley, 2016>
% (damping coefficient formula)
%
classdef ContactForceN_ViscoElasticLinear < ContactForceN
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        stiff_formula   uint8   = uint8.empty;     % flag for type of stiffness formulation
        remove_cohesion logical = logical.empty;   % flag for removing artificial cohesion
    end
    
    %% Constructor method
    methods
        function this = ContactForceN_ViscoElasticLinear()
            this = this@ContactForceN(ContactForceN.VISCOELASTIC_LINEAR);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            this.stiff_formula   = this.ENERGY;
            this.remove_cohesion = true;
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,int)
            % Needed properties
            r    = int.eff_radius;
            m    = int.eff_mass;
            y    = int.eff_young;
            v0   = abs(int.kinemat.v0_n);
            e    = this.restitution;
            beta = pi/log(e);
            
            % Stiffness coefficient
            switch this.stiff_formula
                case this.ENERGY
                    this.stiff = 1.053*(v0*r*y^2*sqrt(m))^(2/5);
                case this.OVERLAP
                    this.stiff = 1.053*(v0*r*y^2*sqrt(m))^(2/5) * (exp(-atan(beta)/beta))^2;
                case this.TIME
                    this.stiff = 1.198*(v0*r*y^2*sqrt(m))^(2/5) * (1+beta^(-2));
            end
            
            % Damping coefficient
            if (isempty(this.damp))
                this.damp = sqrt(4*m*this.stiff/(1+beta^2));
            end
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Needed properties
            dir  = int.kinemat.dir_n;
            ovlp = int.kinemat.ovlp_n;
            vel  = int.kinemat.vel_n;
            k    = this.stiff;
            d    = this.damp;
            
            % Force modulus (elastic and viscous contributions)
            f = k * ovlp + d * vel;
            
            % Remove artificial cohesion
            if (f < 0 && this.remove_cohesion)
                f = 0;
            end
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * dir;
        end
    end
end