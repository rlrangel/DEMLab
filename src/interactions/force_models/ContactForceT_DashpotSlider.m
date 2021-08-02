%% ContactForceT_DashpotSlider class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_DashpotSlider < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Contact parameters
        damp double = double.empty;   % damping coefficient
        fric double = double.empty;   % friction coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_DashpotSlider()
            this = this@ContactForceT(ContactForceT.DASHPOT_SLIDER);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            
        end
        
        %------------------------------------------------------------------
        function this = setParameters(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (viscous and friction contributions)
            fv = this.damp * int.kinemat.vel_t;
            ff = this.fric * norm(int.cforcen.total_force); 
            
            % Limit elastic force by Coulomb law
            f = min(abs(fv),abs(ff));
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end