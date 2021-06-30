%% Wall_Line2D class
%
%% Description
%
%% Implementation
%
classdef Wall_Line2D < Wall
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
        function this = Wall_Line2D()
            this = this@Wall(Wall.LINE2D);
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function d = distanceFromParticle(this,particle)
            
        end
    end
end