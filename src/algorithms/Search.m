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
        type            int8     = uint8.empty;      % flag for type of search
        freq            int32    = int32.empty;      % frequency of search (in steps)
        interact_common Interact = Interact.empty;   % base object of the Interact class common to all interactions
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
        applyDefaultProps(this);
    end
    
    %% Public methods
    methods
        
    end
end