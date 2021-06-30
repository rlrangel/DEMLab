%% BBox class
%
%% Description
%
%% Subclasses
%
%% Implementation
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
        interval double = double.empty;   % time interval of activation
    end
    
    %% Constructor method
    methods
        function this = BBox(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = BBox_Rectangle;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        do = removeParticle(this,particle,time);
    end
    
    %% Public methods
    methods
        
    end
end