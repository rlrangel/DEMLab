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
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        
    end
end