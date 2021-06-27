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
        coord_ini = [];   % coordinates of initial point
        coord_end = [];   % coordinates of final point
    end
    
    %% Constructor method
    methods
        function this = Wall_Line2D()
            this = this@Wall(Wall.LINE2D);
        end
    end
    
    %% Public methods
    methods
        
    end
end