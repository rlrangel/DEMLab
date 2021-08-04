%% ContactForceT_SDSNonlinear class
%
%% Description
%
%% Implementation
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
        function this = setParameters(this,int)
            if (this.formula == this.TTI && isempty(this.damp))
                this.damp = int.cforcen.damp;
            end
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            switch this.formula
                case this.DD
                    this.stiff = 16 * int.eff_shear * sqrt(int.eff_radius * int.kinemat.ovlp_n) / 3;
                    f = this.stiff * int.kinemat.ovlp_t;
                case this.LTH
                    max_ovlp = this.fric * int.kinemat.ovlp_n * (2 - int.eff_poisson) / (2 - 2 * int.eff_poisson);
                    a  = 1 - min(abs(int.kinemat.ovlp_t),max_ovlp) / max_ovlp;
                    fe = this.fric * norm(int.cforcen.total_force) * (1 - a^(3/2));
                    fv = this.damp * sqrt(6 * int.eff_mass * this.fric * norm(int.cforcen.total_force) * sqrt(a) / max_ovlp) * int.kinemat.vel_t;
                    f  = fe + fv;
                case this.ZZY
                    max_ovlp = this.fric * int.kinemat.ovlp_n * (2 - int.eff_poisson) / (2 - 2 * int.eff_poisson);
                    a  = 1 - min(abs(int.kinemat.ovlp_t),max_ovlp) / max_ovlp;
                    fe = this.fric * norm(int.cforcen.total_force) * (1 - a^(3/2));
                    fv = this.damp / (2 * int.eff_shear * max_ovlp) * (1 - 0.4 * this.damp * abs(int.kinemat.vel_t) / (2 * int.eff_shear * max_ovlp)) * (1.5 * this.fric * norm(int.cforcen.total_force) * sqrt(a)) * int.kinemat.vel_t;
                    f  = fe + fv;
                case this.TTI
                    this.stiff = sqrt(2 * int.eff_radius) * int.eff_young * sqrt(int.kinemat.ovlp_n) / ((2 - int.eff_poisson) * (1 + int.eff_poisson));
                    fe = this.stiff * int.kinemat.ovlp_t;
                    fv = this.damp  * int.kinemat.vel_t;
                    f  = fe + fv;
            end
            
            % Limit viscoelastic force by Coulomb law
            ff = this.fric * norm(int.cforcen.total_force);
            f  = min(abs(f),abs(ff));
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end