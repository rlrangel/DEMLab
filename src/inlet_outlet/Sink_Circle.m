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
    
    %% Public methods: implementation of superclass declarations
    methods
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