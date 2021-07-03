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
            this.total_force = this.spring_coeff * interact.kinematics.ovlp_t;
        end
    end
end