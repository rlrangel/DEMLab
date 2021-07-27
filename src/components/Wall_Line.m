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
        function setFCTranslation(this,time,dt)
            if (this.free_mech)
                return;
            end
            
            vel = [0;0];
            for i = 1:length(this.fc_translation)
                if (this.fc_translation(i).isActive(time))
                    vel = vel + this.fc_translation(i).getValue(time);
                end
            end
            
            % Set end coordinates
            this.coord_ini = this.coord_ini + vel * dt;
            this.coord_end = this.coord_end + vel * dt;
        end
    end
end