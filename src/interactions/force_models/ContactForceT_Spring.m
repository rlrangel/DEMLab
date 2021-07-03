%% ContactForceT_Spring class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_Spring < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        spring_coeff double = double.empty;   % spring coefficient value
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Spring()
            this = this@ContactForceT(ContactForceT.SPRING);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setParameters(~,~)
            
        end
        
        %------------------------------------------------------------------
        function evalForce(this,interact)
            % Force modulus (elastic contribution only)
            f = this.spring_coeff * interact.kinematics.ovlp_t;
            
            % Total normal force vector (against deformation)
            this.total_force = -f * interact.kinematics.dir_t;
        end
    end
end