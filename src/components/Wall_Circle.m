%% Wall_Circle class
%
%% Description
%
%% Implementation
%
classdef Wall_Circle < Wall
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Position
        center double = double.empty;   % coordinates of center point
        radius double = double.empty;   % radius
    end
    
    %% Constructor method
    methods
        function this = Wall_Circle()
            this = this@Wall(Wall.CIRCLE);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            % Flags for free/fixed wall
            this.free_mech  = true;
            this.free_therm = true;
            
            % Thermal state variables
            this.temperature = 0;
        end
        
        %------------------------------------------------------------------
        function setFCVelocity(this,time,dt)
            if (this.free_mech)
                return;
            end
            
            vel = [0;0];
            for i = 1:length(this.fc_velocity)
                if (this.fc_velocity(i).isActive(time))
                    vel = vel + this.fc_velocity(i).getValue(time);
                end
            end
            
            % Set center coordinates
            this.center = this.center + vel * dt;
        end
    end
end