%% RollResist_Constant class
%
%% Description
%
% This is a sub-class of the <rollresist.html RollResist> class for the
% implementation of the *Constant* rolling resistance torque model.
%
% This model assumes that a constant resistance torque (not dependent on
% relative rotation velocity), but depending of normal force, is applied
% against the relative rotation.
%
% *References*:
%
% * <https://doi.org/10.1016/S0378-4371(99)00183-1
% Y.C. Zhou, B.D. Wright, R.Y. Yang, B.H. Xu and A.B. Yu.
% Rolling friction in the dynamic simulation of sandpile formation, _Physica A_, 269(2-4):536-553, 1999>
% (proposal).
%
% * <https://doi.org/10.1016/j.powtec.2010.09.030
% J. Ai, J.F. Chen, J.M. Rotter and J.Y. Ooi.
% Assessment of rolling resistance models in discrete element simulations, _Powder Technol._, 206(3):269-282, 2011>
% (review).
%
classdef RollResist_Constant < RollResist
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Contact parameters
        resist double = double.empty;   % rolling resistance coefficient
    end
    
    %% Constructor method
    methods
        function this = RollResist_Constant()
            this = this@RollResist(RollResist.CONSTANT);
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
        function this = evalTorque(this,int)
            % Needed properties
            dir = -int.kinemat.vel_ang;
            res = this.resist;
            r   = int.eff_radius;
            f   = norm(int.cforcen.total_force);
            
            % Total torque  (against relative rotation)
            this.torque = dir * res * r * f;
        end
    end
end