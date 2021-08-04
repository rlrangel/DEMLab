%% ContactForceT_Spring class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_Spring < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        auto_stiff logical = logical.empty;   % flag for computing spring stiffness automatically
        
        % Contact parameters
        stiff double = double.empty;   % stiffness coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Spring()
            this = this@ContactForceT(ContactForceT.SPRING);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            this.auto_stiff = true;
        end
        
        %------------------------------------------------------------------
        function this = setParameters(this,int)
            if (this.auto_stiff)
                this.stiff = (1-int.eff_poisson)/(1-int.eff_poisson/2) * int.cforcen.stiff;
            end
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (elastic contribution only)
            f = this.stiff * int.kinemat.ovlp_t;
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end