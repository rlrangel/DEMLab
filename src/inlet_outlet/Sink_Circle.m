%% Sink_Circle class
%
%% Description
%
%% Implementation
%
classdef Sink_Circle < Sink
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Sink_Circle()
            this = this@Sink(Sink.CIRCLE);
        end
    end
    
    %% Public methods
    methods
        
    end
end