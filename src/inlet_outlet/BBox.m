%% BBox (Bounding box) class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of bounding
% boxes.
%
% A bounding box is used to limit the simulation domain.
% Particles that are outside the bounding box limits are removed from the
% simulation.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <bbox_rectangle.html BBox_Rectangle> (default)
% * <bbox_circle.html BBox_Circle>
% * <bbox_polygon.html BBox_Polygon>
%
classdef BBox < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of bounding box shapes
        RECTANGLE = uint8(1);
        CIRCLE    = uint8(2);
        POLYGON   = uint8(3);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type     uint8  = uint8.empty;    % flag for type of bounding box shape
        interval double = double.empty;   % time interval of activation (initial,final)
    end
    
    %% Constructor method
    methods
        function this = BBox(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = BBox_Rectangle;
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