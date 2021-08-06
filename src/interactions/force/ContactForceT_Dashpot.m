%% ContactForceT_Dashpot class
%
%% Description
%
% This is a sub-class of the <contactforcet.html ContactForceT> class for
% the implementation of the *Simple Dashpot* tangent contact force model.
%
% This model assumes that the tangent contact force has only a viscous
% component $F_{t}^{v}$, provided by a linear dashpot.
%
% $$\left \{ F_{t} \right \} = -F_{t}^{v}\hat{t}$$
%
% $$F_{t}^{v} = \eta_{t} \dot{\delta_{t}}$$
%
% The tangent damping coefficient $\eta_{t}$ must be provided.
%
% *Notation*:
%
% $\hat{t}$: Tangent direction between elements
%
% $\dot{\delta_{t}}$: Time rate of change of tangent overlap
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