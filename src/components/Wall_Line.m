%% Wall_Line class
%
%% Description
%
% This is a sub-class of the <wall.html Wall> class for the
% implementation of *Line* rigid walls.
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
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            % Behavior flags
            this.fixed_motion = false;
            this.fixed_therm  = false;
            
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
            coord_mid = (this.coord_ini+this.coord_end)/2;
            for i = 1:length(this.fc_translation)
                if (this.fc_translation(i).isActive(time))
                    vel = this.fc_translation(i).getValue(time);
                    
                    % Velocity
                    this.veloc_trl = this.veloc_trl + vel;
                    
                    % Mid-point coodinates
                    coord_mid = coord_mid + vel * dt;
                end
            end
            
            % Rotation
            ang = atan2((this.coord_end(2)-this.coord_ini(2)),((this.coord_end(1)-this.coord_ini(1))));
            for i = 1:length(this.fc_rotation)
                if (this.fc_rotation(i).isActive(time))
                    vel = this.fc_rotation(i).getValue(time);
                    
                    % Velocity
                    this.veloc_rot = this.veloc_rot + vel;
                    
                    % Angular orientation
                    ang = ang + vel * dt;
                end
            end
            
            % New coordinates
            L = this.len/2;
            x1 = coord_mid(1) - L * cos(ang);
            y1 = coord_mid(2) - L * sin(ang);
            x2 = coord_mid(1) + L * cos(ang);
            y2 = coord_mid(2) + L * sin(ang);
            this.coord_ini = [x1;y1];
            this.coord_end = [x2;y2];
        end
    end
end