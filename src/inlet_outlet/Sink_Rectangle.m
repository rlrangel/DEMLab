%% Sink_Rectangle class
%
%% Description
%
%% Implementation
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
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function do = removeParticle(this,particle,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            if (any(particle.coord > this.limit_min) &&...
                any(particle.coord < this.limit_max))
                do = true;
            else
                do = false;
            end
        end
    end
end