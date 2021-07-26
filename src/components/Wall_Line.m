%% Wall_Line class
%
%% Description
%
%% Implementation
%
classdef Wall_Line < Wall
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Position
        coord_ini double = double.empty;   % coordinates of initial point
        coord_end double = double.empty;   % coordinates of final point
        
        % Geometric properties
        len double = double.empty;   % length of line
    end
    
    %% Constructor method
    methods
        function this = Wall_Line()
            this = this@Wall(Wall.LINE);
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
            vel = [0;0];
            for i = 1:length(this.fc_velocity)
                if (this.fc_velocity(i).isActive(time))
                    vel = vel + this.fc_velocity(i).getValue(time);
                end
            end
            
            % Set end coordinates
            this.coord_ini = vel * dt;
            this.coord_end = vel * dt;
        end
    end
end