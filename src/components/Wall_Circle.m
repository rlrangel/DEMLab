%% Wall_Circle class
%
%% Description
%
% This is a sub-class of the <wall.html Wall> class for the
% implementation of *Circle* rigid walls.
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
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            % Behavior flags
            this.fixed_motion = false;
            this.fixed_therm  = false;
            this.adiabatic    = false;
            
            % Mechanical state variables
            this.veloc_trl = [0;0];
            this.veloc_rot = 0;
            
            % Thermal state variables
            this.temperature = 0;
        end
        
        %------------------------------------------------------------------
        function setFCMotion(this,time,dt)
            this.veloc_trl = [0;0];
            this.veloc_rot = 0;
            if (~this.fixed_motion)
                return;
            end
            
            % Translation
            for i = 1:length(this.fc_translation)
                if (this.fc_translation(i).isActive(time))
                    this.veloc_trl = this.veloc_trl + this.fc_translation(i).getValue(time);
                end
            end
            this.center = this.center + this.veloc_trl * dt;
            
            % Rotation
            for i = 1:length(this.fc_rotation)
                if (this.fc_rotation(i).isActive(time))
                    this.veloc_rot = this.veloc_rot + this.fc_rotation(i).getValue(time);
                end
            end
        end
    end
end