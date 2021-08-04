%% ContactForceT_Slider class
%
%% Description
%
% This is a sub-class of the <contactforcet.html ContactForceT> class for
% the implementation of the *Simple Slider* tangent contact force model.
%
% 
%
% References:
%
% * 
%
classdef ContactForceT_Slider < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Contact parameters
        fric double = double.empty;   % friction coefficient
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Slider()
            this = this@ContactForceT(ContactForceT.SLIDER);
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
            % Force modulus (friction contribution only)
            f = this.fric * norm(int.cforcen.total_force);
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end