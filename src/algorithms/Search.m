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
        type int8 = uint8.empty; % flag for type of search
        
        % Parameters
        freq uint32 = uint32.empty; % frequency of search (in steps)
        
        % Base object for common interactions
        b_interact Interact = Interact.empty;   % object of the Interact class for all interactions
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
        
        %------------------------------------------------------------------
        execute(this,drv);
    end
    
    %% Public methods
    methods
        
    end
end