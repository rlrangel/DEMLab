%% ContactForceN_ElastoPlasticLinear class
%
%% Description
%
% This is a sub-class of the <contactforcen.html ContactForceN> class for
% the implementation of the *Linear Elasto-Plastic* normal contact force
% model.
%
% This model assumes that the normal contact force has only an elastic
% component $F_{n}^{e}$ that is provided by a hysteric linear spring.
%
% The hysteric spring stiffness adopts different values depending on
% whether elements approach or depart from each other.
% The unloading stiffness is always greater than the loading stiffness.
% 
% The energy dissipation in this model is due to the spring hysteresis and
% it is able to simulate the plastic deformation of elements during
% collisions.
%
% $$\left \{ F_{n} \right \} = -F_{n}^{e}\hat{n}$$
%
% * *Loading* ($\dot{\delta_{n}}>0$):
%
% $$F_{n}^{e} = K_{n}^{L}\delta_{n}$$
%
% * *Unloading (before detachment)* ($\dot{\delta_{n}}<0, \delta_{n}>\delta_{n}^{res}$):
%
% $$F_{n}^{e} = K_{n}^{U} \left ( \delta_{n}-\delta_{n}^{res} \right )$$
%
% * *Unloading (after detachment)* ($\dot{\delta_{n}}<0, \delta_{n}\leq \delta_{n}^{res}$):
%
% $$F_{n}^{e} = 0$$
%
% The loading stiffness coefficient $K_{n}^{L}$ can be computed by 3
% different formulas:
%
% * *Equivalent energy*:
%
% $$K_{n} = 1.053 \left ( \dot{\delta}_{n}^{0}R_{eff}E_{eff}^{2}\sqrt{m_{eff}} \right )^{\frac{2}{5}}$$
%
% * *Equivalent overlap*:
%
% $$K_{n} = 1.053\left ( \dot{\delta}_{n}^{0}R_{eff}E_{eff}^{2}\sqrt{m_{eff}} \right )^{\frac{2}{5}}\left ( 1+ \beta^{-2} \right )$$
%
% * *Equivalent time*:
%
% $$K_{n} = 1.198\left ( \dot{\delta}_{n}^{0}R_{eff}E_{eff}^{2}\sqrt{m_{eff}} \right )^{\frac{2}{5}} \left ( exp \left ( -\frac{tg^{-1}(\beta)}{\beta} \right ) \right )^{2}$$
%
% The unloading stiffness coefficient $K_{n}^{U}$ can be computed by 2
% different formulas:
%
% * *Constant*:
%
% $$K_{n}^{U} = \frac{K_{n}^{L}}{e^{2}}$$
%
% * *Variable*:
%
% $$K_{n}^{U} = K_{n}^{L}+SF_{n}^{max}$$
%
% $$F_{n}^{max} = K_{n}^{L}\dot{\delta}_{n}^{0}\sqrt{\frac{m_{eff}}{K_{n}^{L}}}$$
%
% The residual overlap due to palstic deformation is computed as:
%
% $$\delta_{n}^{res} = \dot{\delta}_{n}^{0} \sqrt{\frac{m_{eff}}{K_{n}^{L}}} (1-e^{2})$$
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
% $e$: Normal coefficient of restitution
%
% $\beta = \frac{\pi}{ln(e)}$
%
% $S$: Variable unload stiffness coefficient parameter
%
% *References*:
%
% * <https://doi.org/10.1122/1.549893
% O.R. Walton and R.L. Braun.
% Viscosity, granular temperature, and stress calculations for shearing assemblies of inelastic, frictional disks, _J. Rheol._, 30:949, 1986>
% (proposal).
%
classdef ContactForceN_ElastoPlasticLinear < ContactForceN
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        load_stiff_formula   uint8 = uint8.empty;   % flag for type of loading stiffness formulation
        unload_stiff_formula uint8 = uint8.empty;   % flag for type of unloading stiffness formulation
        
        % Contact parameters
        unload_stiff double = double.empty;   % unloading spring stiffness coefficient
        unload_param double = double.empty;   % variable unload stiffness coefficient parameter
        residue      double = double.empty;   % residual overlap
    end
    
    %% Constructor method
    methods
        function this = ContactForceN_ElastoPlasticLinear()
            this = this@ContactForceN(ContactForceN.ELASTOPLASTIC_LINEAR);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            this.load_stiff_formula   = this.ENERGY;
            this.unload_stiff_formula = this.CONSTANT;
        end
        
        %------------------------------------------------------------------
        function this = setParameters(this,int)
            % Needed properties
            r    = int.eff_radius;
            m    = int.eff_mass;
            y    = int.eff_young;
            v0   = abs(int.kinemat.v0_n);
            e    = this.restitution;
            e2   = e^2;
            S    = this.unload_param;
            beta = pi/log(e);
            
            % Loading spring stiffness coefficient
            switch this.load_stiff_formula
                case this.ENERGY
                    this.stiff = 1.053*(v0*r*y^2*sqrt(m))^(2/5);
                case this.OVERLAP
                    this.stiff = 1.053*(v0*r*y^2*sqrt(m))^(2/5) * exp(-atan(beta)/beta)^2;
                case this.TIME
                    this.stiff = 1.198*(v0*r*y^2*sqrt(m))^(2/5) * (1+1/beta^2);
            end
            
            % Unloading spring stiffness coefficient
            switch this.unload_stiff_formula
                case this.CONSTANT
                    this.unload_stiff = this.stiff / e2;
                case this.VARIABLE
                    fmax = this.stiff * v0 * sqrt(m/this.stiff);
                    this.unload_stiff = this.stiff + S * fmax;
            end
            
            % Residual overlap
            this.residue = v0 * sqrt(m/this.stiff) * (1-e2);
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Needed properties
            dir  = int.kinemat.dir_n;
            ovlp = int.kinemat.ovlp_n;
            vel  = int.kinemat.vel_n;
            res  = this.residue;
            kl   = this.stiff;
            ku   = this.unload_stiff;
            
            % Elastic force according to loading or unloading behavior
            if (vel > 0) % loading
                f = kl * ovlp;
            elseif (vel < 0 && ovlp > res) % unloading
                f = ku * (ovlp - res);
            else
                f = 0;
            end
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * dir;
        end
    end
end