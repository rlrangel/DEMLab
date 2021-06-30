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
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function d = distanceFromParticle(this,particle)
            d = norm(this.center-particle.coord) - this.radius - particles.radius;
        end
    end
end