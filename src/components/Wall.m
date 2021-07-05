%% Wall class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Wall < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of wall
        LINE2D = uint8(1);
        CIRCLE = uint8(2);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8  = uint8.empty;    % flag for type of wall
        id   uint32 = uint32.empty;   % identification number
        
        % Physical properties
        material Material = Material.empty;   % handle to object of Material class
        
        % Neighbours Interactions
        interacts Interact = Interact.empty;    % handles to objects of Interact class
    end
    
    %% Constructor method
    methods
        function this = Wall(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Wall_Line2D;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end