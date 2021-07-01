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
            P = particle.coord;
            A = this.coord_ini;
            B = this.coord_end;
            M = B - A;
            
            % Running parameter at the orthogonal intersection
            t = dot(M,P-A)/this.len^2;
            
            % Distance between point and line segment
            if (t <= 0)
                d = norm(P-A);
            elseif (t >= 1)
                d = norm(P-B);
            else
                d = norm(P-(A + t * M));
            end
        end
    end
end