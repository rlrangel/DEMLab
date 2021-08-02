%% ContactForceT_Slider class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_Slider < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        friction double = double.empty;   % friction coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Slider()
            this = this@ContactForceT(ContactForceT.SLIDER);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function this = setParameters(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalForce(this,int)
            % Force modulus (friction contribution only)
            f = this.friction * abs(int.cforcen.total_force);
            
            % Total tangential force vector (against motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end