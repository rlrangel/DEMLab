%% Search class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Search < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of search
        SIMPLE_LOOP = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type int8    = uint8.empty;     % flag for type of search
        done logical = logical.empty;   % flag for identifying if search has been done in a time step
        
        % Parameters
        freq     uint32 = uint32.empty;   % frequency of search (in steps)
        max_dist double = uint32.empty;   % threshold neighbour distance (exclusive) to create an interaction
        
        % Base object for common interactions
        b_interact Interact = Interact.empty;   % handle to object of Interact class for all interactions
    end
    
    %% Constructor method
    methods
        function this = Search(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Search_SimpleLopp;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        execute(this,drv);
    end
    
    %% Public methods
    methods
        
    end
end