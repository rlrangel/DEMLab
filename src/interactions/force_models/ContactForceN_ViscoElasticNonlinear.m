%% ContactForceN_ViscoElasticNonlinear class
%
%% Description
%
%% Implementation
%
classdef ContactForceN_ViscoElasticNonlinear < ContactForceN
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        damp_formula    uint8   = uint8.empty;     % flag for type of damping formulation
        remove_cohesion logical = logical.empty;   % flag for removing artificial cohesion
        
        % Constant parameters
        stiff double = double.empty;   % spring stiffness coefficient
        damp  double = double.empty;   % damping coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceN_ViscoElasticNonlinear()
            this = this@ContactForceN(ContactForceN.VISCOELASTIC_NONLINEAR);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
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
                this.damp = -2.2664 * log(e) * sqrt(m * this.stiff) / sqrt(10.1354 + log(e)^2);
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
            
            % Elastic force
            fe = k * ovlp^(3/2);
            
            % Viscous force
            switch this.damp_formula
                case this.TTI
                    fv = d * ovlp^(1/4) * vel;
                case this.KK
                    fv = d * ovlp^(1/2) * vel;
            end
            
            % Force modulus
            f = fe + fv;
            
            % Remove artificial cohesion
            if (f < 0 && this.remove_cohesion)
                f = 0;
            end
            
            % Total normal force vector (against deformation and velocity)
            this.total_force = -f * dir;
        end
    end
end