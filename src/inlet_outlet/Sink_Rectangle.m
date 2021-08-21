%% Sink_Rectangle class
%
%% Description
%
% This is a sub-class of the <sink.html Sink> class for the implementation
% of *Rectangle* sinks.
%
classdef Sink_Rectangle < Sink
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        limit_min double = double.empty;   % coordinates of minimum limits (bottom-left corner)
        limit_max double = double.empty;   % coordinates of maximum limits (top-right corner)
    end
    
    %% Constructor method
    methods
        function this = Sink_Rectangle()
            this = this@Sink(Sink.RECTANGLE);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.limit_min = [0,0];
            this.limit_max = [0,0];
        end
        
        %------------------------------------------------------------------
        function do = removeParticle(this,p,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            do = (any(p.coord > this.limit_min) && any(p.coord < this.limit_max));
        end
    end
end