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
        center = [];   % coordinates of center point
        radius = 0;    % radius
    end
    
    %% Constructor method
    methods
        function this = Wall_Circle()
            this = this@Wall(Wall.CIRCLE);
        end
    end
    
    %% Public methods
    methods
        
    end
end