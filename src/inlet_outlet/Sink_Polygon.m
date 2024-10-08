%% Sink_Polygon class
%
%% Description
%
% This is a sub-class of the <Sink.html Sink> class for the implementation
% of *Polygon* sinks.
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
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.coord_x = [0,0,0,0];
            this.coord_y = [0,0,0,0];
            warning('off','MATLAB:inpolygon:ModelingWorldLower');
        end
        
        %------------------------------------------------------------------
        function do = removeParticle(this,p,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            try
                do = (inpolygon(p.coord(1),p.coord(2),this.coord_x,this.coord_y));
            catch
                do = false;
            end
        end
    end
end