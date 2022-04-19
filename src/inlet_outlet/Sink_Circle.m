%% Sink_Circle class
%
%% Description
%
% This is a sub-class of the <Sink.html Sink> class for the implementation
% of *Circle* sinks.
%
classdef Sink_Circle < Sink
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        center double = double.empty;   % coordinates of center point
        radius double = double.empty;   % radius
    end
    
    %% Constructor method
    methods
        function this = Sink_Circle()
            this = this@Sink(Sink.CIRCLE);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.center = [0,0];
            this.radius = 0;
        end
        
        %------------------------------------------------------------------
        function do = removeParticle(this,p,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            do = (norm(p.coord-this.center) < this.radius);
        end
    end
end