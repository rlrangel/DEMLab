%% Sink_Polygon class
%
%% Description
%
%% Implementation
%
classdef Sink_Polygon < Sink
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Sink_Polygon()
            this = this@Sink(Sink.POLYGON);
        end
    end
    
    %% Public methods
    methods
        
    end
end