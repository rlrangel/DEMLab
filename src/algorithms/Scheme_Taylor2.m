%% Scheme_Taylor2 (Taylor 2nd Order) class
%
%% Description
%
%% Implementation
%
classdef Scheme_Taylor2 < Scheme
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Scheme_Taylor2()
            this = this@Scheme(Scheme.TAYLOR_2);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function updatePosition(~,p,dt)
            p.coord     = p.coord     + p.veloc_trl * dt + 0.5 * p.accel_trl * dt^2;
            p.veloc_trl = p.veloc_trl + p.accel_trl * dt;
        end
        
        %------------------------------------------------------------------
        function updateOrientation(~,p,dt)
            p.orient    = p.orient    + p.veloc_rot * dt + 0.5 * p.accel_rot * dt^2;
            p.veloc_rot = p.veloc_rot + p.accel_rot * dt;
        end
        
        %------------------------------------------------------------------
        function updateTemperature(~,~,~)
            % Not available
        end
    end
end