%% ContactForceT_SpringSlider class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_SpringSlider < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Formulation options
        auto_stiff logical = logical.empty;   % flag for computing spring stiffness automatically
        
        % Contact parameters
        stiff double = double.empty;   % stiffness coefficient
        fric  double = double.empty;   % friction coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_SpringSlider()
            this = this@ContactForceT(ContactForceT.SPRING_SLIDER);
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
            % Force modulus (elastic and friction contributions)
            fe = this.stiff * int.kinemat.ovlp_t;
            ff = this.fric  * norm(int.cforcen.total_force);
            
            % Limit elastic force by Coulomb law
            f = min(abs(fe),abs(ff));
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end