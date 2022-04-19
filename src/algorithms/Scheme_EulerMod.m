%% Scheme_EulerMod class
%
%% Description
%
% This is a sub-class of the <Scheme.html Scheme> class for the
% implementation of the time integration scheme *Modified Euler*.
%
% * *Translational motion*:
%
% $$v_{i} = v_{i-1} + a_{i} \Delta t$$
%
% $$x_{i} = x_{i-1} + v_{i} \Delta t$$
%
% * *Rotational motion*:
%
% $$\omega_{i} = \omega_{i-1} + \alpha_{i} \Delta t$$
%
% $$\theta_{i} = \theta_{i-1} + \omega_{i} \Delta t$$
%
% *Notation*:
%
% $\Delta t$: Time increment
%
% $x$: Coordinates
%
% $v$: Translational velocity
%
% $a$: Translational acceleration
%
% $\theta$: Angular orientation
%
% $\omega$: Angular velocity
%
% $\alpha$: Angular acceleration
%
classdef Scheme_EulerMod < Scheme
    %% Constructor method
    methods
        function this = Scheme_EulerMod()
            this = this@Scheme(Scheme.EULER_MODIFIED);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function updatePosition(~,p,dt)
            p.veloc_trl = p.veloc_trl + p.accel_trl * dt;
            p.coord     = p.coord     + p.veloc_trl * dt;
        end
        
        %------------------------------------------------------------------
        function updateOrientation(~,p,dt)
            p.veloc_rot = p.veloc_rot + p.accel_rot * dt;
            p.orient    = p.orient    + p.veloc_rot * dt;
        end
        
        %------------------------------------------------------------------
        function updateTemperature(~,~,~)
            % Not available
        end
    end
end