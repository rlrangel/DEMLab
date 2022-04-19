%% RollResist_Viscous class
%
%% Description
%
% This is a sub-class of the <RollResist.html RollResist> class for the
% implementation of the *Viscous* rolling resistance torque model.
%
% This model assumes that the resistance torque dependends on the relative
% rotation velocity and normal force and is applied against the relative
% rotation.
%
% $$M = -\hat{\omega} \mu R_{eff} \left | F_{n} \right | \left | V_{\omega} \right |$$
%
% *Notation*:
%
% $\hat{\omega}$: Relative angular velocity
%
% $\mu$: Rolling resistance coefficient
%
% $R_{eff}$: Effective contact radius
%
% $F_{n}$: Normal contact force vector
%
% $V_{\omega}$: Relative velocity due to rotation at contact point
%
% *References*:
%
% * <https://doi.org/10.1209/epl/i1998-00281-7
% N.V. Brilliantov and T. poschel.
% Rolling friction of a viscous sphere on a hard plane, _Europhysics Letters_, 42(5):511-516, 1998>
% (proposal)
%
% * <https://doi.org/10.1016/j.powtec.2010.09.030
% J. Ai, J.F. Chen, J.M. Rotter and J.Y. Ooi.
% Assessment of rolling resistance models in discrete element simulations, _Powder Technol._, 206(3):269-282, 2011>
% (review)
%
classdef RollResist_Viscous < RollResist
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Contact parameters
        resist double = double.empty;   % rolling resistance coefficient
    end
    
    %% Constructor method
    methods
        function this = RollResist_Viscous()
            this = this@RollResist(RollResist.VISCOUS);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalTorque(this,int)
            % Needed properties
            dir = -sign(int.kinemat.vel_ang);
            res = this.resist;
            r   = int.eff_radius;
            f   = norm(int.cforcen.total_force);
            v   = norm(int.kinemat.vel_rot);
            
            % Total torque (against relative rotation)
            this.torque = dir * res * r * f * v;
        end
    end
end