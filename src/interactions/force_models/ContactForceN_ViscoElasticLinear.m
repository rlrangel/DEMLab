%% ContactForceN_ViscoElasticLinear class
%
%% Description
%
%% Implementation
%
classdef ContactForceN_ViscoElasticLinear < ContactForceN
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        stiff_formula   int8    = uint8.empty;     % flag for type of stiffness formulation
        remove_cohesion logical = logical.empty;   % flag for removing artificial cohesion
        
        % Constant parameters
        stiff double = double.empty;   % spring stiffness coefficient
        damp  double = double.empty;   % damping coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceN_ViscoElasticLinear()
            this = this@ContactForceN(ContactForceN.VISCOELASTIC_LINEAR);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.stiff_formula   = this.ENERGY;
            this.remove_cohesion = true;
        end
        
        %------------------------------------------------------------------
        function setParameters(this,interact)
            % Needed properties
            r    = interact.eff_radius;
            m    = interact.eff_mass;
            y    = interact.eff_young;
            v0   = interact.kinematics.v0_n;
            e    = this.restitution;
            beta = pi/ln(e);
            
            % Spring stiffness coefficient
            switch this.stiff_formula
                case this.TIME
                    this.stiff = 1.198*(v0*r*y^2*sqrt(m))^(2/5) * (1+1/beta^2);
                case this.OVERLAP
                    this.stiff = 1.053*(v0*r*y^2*sqrt(m))^(2/5) * exp(-atan(beta)/beta)^2;
                case this.ENERGY
                    this.stiff = 1.053*(v0*r*y^2*sqrt(m))^(2/5);
            end
            
            % Damping coefficient
            this.damp = sqrt(4*m*this.stiff/(1+beta^2));
        end
        
        %------------------------------------------------------------------
        function evalForce(this,interact)
            % Needed properties
            dir  = interact.kinematics.dir_n;
            ovlp = interact.kinematics.ovlp_n;
            vel  = interact.kinematics.vel_n;
            k    = this.stiff;
            d    = this.damp;
            
            % Force modulus (elastic and viscous contributions)
            f = k * ovlp + d * vel;
            
            % Remove artificial cohesion
            if (this.remove_cohesion && f < 0)
                f = 0;
            end
            
            % Total normal force vector (against deformation and velocity)
            this.total_force = -f * dir;
        end
    end
end