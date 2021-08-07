%% ContactForceT_Slider class
%
%% Description
%
% This is a sub-class of the <contactforcet.html ContactForceT> class for
% the implementation of the *Simple Slider* tangent contact force model.
%
% This model assumes that the tangent contact force has only a friction
% component $F_{t}^{f}$, provided by a slider.
%
% $$\left \{ F_{t} \right \} = -F_{t}^{f}\hat{t}$$
%
% $$F_{t}^{f} = \mu \left | F_{n} \right |$$
%
% The friction coefficient $\mu$ must be provided.
%
% *Notation*:
%
% $\hat{t}$: Tangent direction between elements
%
% $F_{n}$: Normal contact force vector
%
% *References*:
%
% * <https://doi.org/10.1016/0032-5910(86)80048-1
% P.K. Haff and B.T. Werner.
% Computer simulation of the mechanical sorting of grains, _Powder Techn._, 48(3):239-245, 1986>
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
            if (~isempty(int.cforcen))
                f = this.fric * norm(int.cforcen.total_force);
            else
                f = 0;
            end
            
            % Total tangential force vector (against deformation and motion)
            this.total_force = -f * int.kinemat.dir_t;
        end
    end
end