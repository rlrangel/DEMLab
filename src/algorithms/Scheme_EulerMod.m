%% Scheme_EulerMod (Modified Euler) class
%
%% Description
%
%% Implementation
%
classdef Scheme_EulerMod < Scheme
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Scheme_EulerMod()
            this = this@Scheme(Scheme.EULER_MODIFIED);
        end
    end
    
    %% Public methods: implementation of superclass declarations
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