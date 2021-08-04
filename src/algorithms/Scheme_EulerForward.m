%% Scheme_EulerForward class
%
%% Description
%
% This is a sub-class of the <scheme.html Scheme> class for the
% implementation of the time integration scheme *Forward Euler*.
%
% * Translational motion:
%
% $x_{i} = x_{i-1} + v_{i-1} \times \Delta t$
%
% $v_{i} = v_{i-1} + a_{i} \times \Delta t$
%
% * Rotational motion:
%
% $\theta_{i} = \theta_{i-1} + \omega_{i-1} \times \Delta t$
%
% $\omega_{i} = \omega_{i-1} + \alpha_{i} \times \Delta t$
%
% * Thermal state:
%
% $T_{i} = T_{i-1} + \frac{\partial T}{\partial t}_{i} \times \Delta t$
%
% * Notation
%
% $\Delta t$: Time increment
%
% $x$: Coordinates
%
% $v$: Translational velocity
%
% $a$: Translational acceleration
%
% $\theta$: angular orientation
%
% $\omega$: angular velocity
%
% $\alpha$: angular acceleration
%
% $T$: Temperature
%
classdef Scheme_EulerForward < Scheme
   %% Constructor method
    methods
        function this = Scheme_EulerForward()
            this = this@Scheme(Scheme.EULER_FORWARD);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function updatePosition(~,p,dt)
            p.coord     = p.coord     + p.veloc_trl * dt;
            p.veloc_trl = p.veloc_trl + p.accel_trl * dt;
        end
        
        %------------------------------------------------------------------
        function updateOrientation(~,p,dt)
            p.orient    = p.orient    + p.veloc_rot * dt;
            p.veloc_rot = p.veloc_rot + p.accel_rot * dt;
        end
        
        %------------------------------------------------------------------
        function updateTemperature(~,p,dt)
            p.temperature = p.temperature + p.temp_change * dt;
        end
    end
end