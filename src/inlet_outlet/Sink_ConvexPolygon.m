%% Sink_ConvexPolygon class
%
%% Description
%
%% Implementation
%
classdef Sink_ConvexPolygon < Sink
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Sink_ConvexPolygon()
            this = this@Sink(Sink.CONVEX_POLYGON);
        end
    end
    
    %% Public methods
    methods
        
    end
end