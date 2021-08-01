%% ContactForceN_ElastoPlasticLinear class
%
%% Description
%
%% Implementation
%
classdef ContactForceN_ElastoPlasticLinear < ContactForceN
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        load_stiff_formula   uint8 = uint8.empty;   % flag for type of loading stiffness formulation
        unload_stiff_formula uint8 = uint8.empty;   % flag for type of unloading stiffness formulation
        
        % Constant parameters
        load_stiff   double = double.empty;   % loading spring stiffness coefficient
        unload_stiff double = double.empty;   % unloading spring stiffness coefficient
        unload_param double = double.empty;   % variable unload stiffness coefficient parameter
        residue      double = double.empty;   % residual overlap
    end
    
    %% Constructor method
    methods
        function this = ContactForceN_ElastoPlasticLinear()
            this = this@ContactForceN(ContactForceN.ELASTOPLASTIC_LINEAR);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
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
                case this.TIME
                    this.load_stiff = 1.198*(v0*r*y^2*sqrt(m))^(2/5) * (1+1/beta^2);
                case this.OVERLAP
                    this.load_stiff = 1.053*(v0*r*y^2*sqrt(m))^(2/5) * exp(-atan(beta)/beta)^2;
                case this.ENERGY
                    this.load_stiff = 1.053*(v0*r*y^2*sqrt(m))^(2/5);
            end
            
            % Unloading spring stiffness coefficient
            switch this.unload_stiff_formula
                case this.CONSTANT
                    this.unload_stiff = this.load_stiff / e2;
                case this.VARIABLE
                    fmax = this.load_stiff * v0 * sqrt(m/this.load_stiff);
                    this.unload_stiff = this.load_stiff + S * fmax;
            end
            
            % Residual overlap
            this.residue = v0 * sqrt(m/this.load_stiff) * (1-e2);
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Needed properties
            dir  = int.kinemat.dir_n;
            ovlp = int.kinemat.ovlp_n;
            vel  = int.kinemat.vel_n;
            res  = this.residue;
            kl   = this.load_stiff;
            ku   = this.unload_stiff;
            
            % Elastic force according to loading or unloading behavior
            if (vel > 0) % loading
                f = kl * ovlp;
            elseif (vel < 0 && ovlp > res) % unloading
                f = ku * (ovlp - res);
            else
                f = 0;
            end
            
            % Total normal force vector (against deformation)
            this.total_force = -f * dir;
        end
    end
end