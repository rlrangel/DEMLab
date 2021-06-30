%% Sink_Circle class
%
%% Description
%
%% Implementation
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
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function do = removeParticle(this,particle,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            if (norm(particle.coord-this.center) < this.radius)
                do = true;
            else
                do = false;
            end
        end
    end
end