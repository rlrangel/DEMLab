%% ContactForceT_DashpotSlider class
%
%% Description
%
% This is a sub-class of the <contactforcet.html ContactForceT> class for
% the implementation of the *Dashpot-Slider* tangent contact force model.
%
% This model assumes that the tangent contact force has a viscous component
% $F_{t}^{v}$, provided by a linear dashpot, and a friction component
% $F_{t}^{f}$, provided by a slider, which limits the total force according
% to Coulomb law.
%
% $$\left \{ F_{t} \right \} = min(F_{t}^{v},F_{t}^{f})(-\hat{t})$$
%
% $$F_{t}^{v} = \eta_{t} \dot{\delta_{t}}$$
%
% $$F_{t}^{f} = \mu \left | F_{n} \right |$$
%
% The tangent damping coefficient $\eta_{t}$ and the friction coefficient
% $\mu$ must be provided.
%
% *Notation*:
%
% $\hat{t}$: Tangent direction between elements
%
% $\dot{\delta_{t}}$: Time rate of change of tangent overlap
%
% $F_{n}$: Normal contact force vector
%
% *References*:
%
% * <https://doi.org/10.1016/0032-5910(86)80048-1
% P.K. Haff and B.T. Werner.
% Computer simulation of the mechanical sorting of grains, _Powder Techn._, 48(3):239-245, 1986>
% (proposal).
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