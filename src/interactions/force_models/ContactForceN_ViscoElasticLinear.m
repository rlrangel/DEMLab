%% ContactForceN_ViscoElasticLinear class
%
%% Description
%
%% Implementation
%
classdef ContactForceN_ViscoElasticLinear < ContactForceN
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        stiff_formula   int8    = uint8.empty;     % flag for type of stiffness formulation
        remove_cohesion logical = logical.empty;   % flag for removing artificial cohesion
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
        function evalForces(this,interact)
            % Needed properties
            %effective mass / radius / young
            %restitution coefficient (interaction property!)
            %impact velocity
            %normal direction
            %normal overlap
            %normal overlap rate of change
            
            % Spring stiffness coefficient
            switch this.stiff_formula
                case this.TIME
                    k = ;
                case this.OVERLAP
                    k = ;
                case this.ENERGY
                    k = ;
            end
            
            % Damping coefficient
            d = ;
            
            % Compute elastic and viscous forces
            Fel = k * ovlp_n;
            Fvis = d * vel_n;
            
            % Compute and store total force
            F = -(Fel + Fvis) * dir_n;
        end
    end
end