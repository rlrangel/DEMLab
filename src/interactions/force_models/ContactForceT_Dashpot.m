%% ContactForceT_Dashpot class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_Dashpot < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Contact parameters
        damp double = double.empty;   % damping coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Dashpot()
            this = this@ContactForceT(ContactForceT.DASHPOT);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            
        end
        
        %------------------------------------------------------------------
        function this = setParameters(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (viscous contribution only)
            f = this.damp * int.kinemat.vel_t;
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end