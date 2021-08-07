%% ContactForceN_ViscoElasticNonlinear class
%
%% Description
%
% This is a sub-class of the <contactforcen.html ContactForceN> class for
% the implementation of the *Nonlinear Visco-Elastic* normal contact force
% model.
%
% This model assumes that the normal contact force has an elastic
% $F_{n}^{e}$ and a viscous $F_{n}^{v}$ component, provided by a nonlinear
% spring and dashpot, respectively.
%
% $$\left \{ F_{n} \right \} = (F_{n}^{e} + F_{n}^{v})(-\hat{n})$$
%
% The elastic force is always computed according to Hertz contact theory:
%
% $$F_{n}^{e} = K_{hz} \delta_{n}^{\frac{3}{2}}$$
%
% $$K_{hz} = \frac{4}{3} E_{eff} \sqrt{R_{eff}}$$
%
% The viscous force can be computed by 3 different formulas:
%
% * *TTI (Tsuji, Tanaka & Ishida)*:
%
% $$F_{n}^{v} = \eta_{n} \delta_{n}^{\frac{1}{4}} \dot{\delta_{n}}$$
%
% $$\eta_{n} = -2.2664\frac{ln(e)\sqrt{m_{eff}K_{hz}}}{\sqrt{ln(e)^{2}+10.1354}}$$
%
% * *KK (Kuwabara & Kono)*:
%
% $$F_{n}^{v} = \eta_{n} \delta_{n}^{\frac{1}{2}} \dot{\delta_{n}}$$
%
% * *LH (Lee & Herrmann)*:
%
% $$F_{n}^{v} = \eta_{n} $m_{eff} \dot{\delta_{n}}$$
%
% The damping coefficient $\eta_{n}$ must be provided for models KK and LH.
%
% *Notation*:
%
% $\hat{n}$: Normal direction between elements
%
% $\delta_{n}$: Normal overlap
%
% $\dot{\delta_{n}}$: Time rate of change of normal overlap
%
% $R_{eff}$: Effective contact radius
%
% $E_{eff}$: Effective Young modulus
%
% $m_{eff}$: Effective mass
%
% $e$: Normal coefficient of restitution
%
% *References*:
%
% * <https://doi.org/10.1515/crll.1882.92.156
% H. Hertz.
% Ueber die Beruhrung fester elastischer Korper, _J.f. reine u. Angewandte Math._, 92:156-171, 1882>
% (Hertz contact theory)
%
% * <https://www.cambridge.org/core/books/contact-mechanics/E3707F77C2EBCE727C3911AFBD2E4AC2
% K.L. Johnson.
% _Contact Mechanics_, Cambridge University Press, 1985>
% (Hertz contact theory)
%
% * <https://doi.org/10.1016/0032-5910(92)88030-L
% Y. Tsuji, T. Tanaka and T. Ishida.
% Lagrangian numerical simulation of plug flow of cohesionless particles in a horizontal pipe, _Powder Technol._, 71(3):239-250, 1992>
% (TTI viscous model)
%
% * <https://www.wiley.com/en-ai/Coupled+CFD+DEM+Modeling%3A+Formulation%2C+Implementation+and+Application+to+Multiphase+Flows-p-9781119005131
% H.R. Norouzi, R. Zarghami, R. Sotudeh-Gharebagh and N. Mostoufi.
% _Coupled CFD-DEM Modeling: Formulation, Implementation and Application to Multiphase Flows_, Wiley, 2016>
% (damping coefficient formula in TTI viscous model)
%
% * <https://iopscience.iop.org/article/10.1143/JJAP.26.1230/meta
% G. Kuwabara and K. Kono.
% Restitution coefficient in collision between two spheres, _Jpn. J. Appl. Phys._, 26:1230-1233, 1987>
% (KK viscous model)
%
% * <https://doi.org/10.1088/0305-4470/26/2/021
% J. Lee and H.J. Herrmann.
% Angle of repose and angle of marginal stability-molecular-dynamics of granular particles, _J. Phys. A: Math. Gen._, 26(2):373-383, 1993>
% (LH viscous model)
%
classdef ContactForceN_ViscoElasticNonlinear < ContactForceN
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        damp_formula    uint8   = uint8.empty;     % flag for type of damping formulation
        remove_cohesion logical = logical.empty;   % flag for removing artificial cohesion
    end
    
    %% Constructor method
    methods
        function this = ContactForceN_ViscoElasticNonlinear()
            this = this@ContactForceN(ContactForceN.VISCOELASTIC_NONLINEAR);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            this.damp_formula    = this.TTI;
            this.remove_cohesion = true;
        end
        
        %------------------------------------------------------------------
        function this = setParameters(this,int)
            % Needed properties
            r = int.eff_radius;
            m = int.eff_mass;
            y = int.eff_young;
            e = this.restitution;
            
            % Spring stiffness coefficient (Hertz model)
            this.stiff = 4 * y * sqrt(r) / 3;
            
            % Damping coefficient
            if (this.damp_formula == this.TTI)
                this.damp = -2.2664 * log(e) * sqrt(m * this.stiff) / sqrt(10.1354 + (log(e))^2);
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
            m    = int.eff_mass;
            
            % Elastic force
            fe = k * ovlp^(3/2);
            
            % Viscous force
            switch this.damp_formula
                case this.TTI
                    fv = d * ovlp^(1/4) * vel;
                case this.KK
                    fv = d * ovlp^(1/2) * vel;
                case this.LH
                    fv = d * m * vel;
            end
            
            % Force modulus
            f = fe + fv;
            
            % Remove artificial cohesion
            if (f < 0 && this.remove_cohesion)
                f = 0;
            end
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * dir;
        end
    end
end