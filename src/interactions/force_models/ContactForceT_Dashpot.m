%% ContactForceT_Dashpot class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_Dashpot < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        damp double = double.empty;   % damping coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Dashpot()
            this = this@ContactForceT(ContactForceT.DASHPOT);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function this = setParameters(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (viscous contribution only)
            f = this.damp * int.kinemat.vel_t;
            
            % Total tangential force vector (against motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end