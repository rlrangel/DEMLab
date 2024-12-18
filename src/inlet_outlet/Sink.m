%% Sink class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of sinks.
%
% A sink is used to insert holes into the simulation domain.
% Particles that are inside the sink limits are removed from the
% simulation.
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <Sink_Rectangle.html Sink_Rectangle> (default)
% * <Sink_Circle.html Sink_Circle>
% * <Sink_Polygon.html Sink_Polygon>
%
classdef Sink < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of sink shapes
        RECTANGLE = uint8(1);
        CIRCLE    = uint8(2);
        POLYGON   = uint8(3);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type     uint8  = uint8.empty;    % flag for type of sink shape
        interval double = double.empty;   % time interval of activation (initial,final)
    end
    
    %% Constructor method
    methods
        function this = Sink(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Sink_Rectangle;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        do = removeParticle(this,particle,time);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function is = isActive(this,time)
            is = isempty(this.interval) || (time >= min(this.interval) && time <= max(this.interval));
        end
    end
end