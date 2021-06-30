%% Sink_Polygon class
%
%% Description
%
%% Implementation
%
classdef Sink_Polygon < Sink
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        coord_x double = double.empty;   % vector of X coodinates of polygon points
        coord_y double = double.empty;   % vector of Y coodinates of polygon points
    end
    
    %% Constructor method
    methods
        function this = Sink_Polygon()
            this = this@Sink(Sink.POLYGON);
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function do = removeParticle(this,particle,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            if (inpolygon(particle.coord(1),particle.coord(2),this.coord_x,this.coord_y))
                do = true;
            else
                do = false;
            end
        end
    end
end