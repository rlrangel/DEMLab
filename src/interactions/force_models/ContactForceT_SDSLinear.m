%% ContactForceT_SDSLinear class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_SDSLinear < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        auto_stiff logical = logical.empty;   % flag for computing spring stiffness automatically
        auto_damp  logical = logical.empty;   % flag for computing damping stiffness automatically
        
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
                this.stiff = (1-int.eff_poisson)/(1-int.eff_poisson/2) * int.cforcen.stiff;
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
            ff = this.fric  * norm(int.cforcen.total_force);
            
            % Limit viscoelastic force by Coulomb law
            f = min(abs(fe+fv),abs(ff));
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end