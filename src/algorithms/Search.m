%% Search class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of
% interactions search algorithms.
%
% A search algorithm is invoked frequently during the simulation to
% identify the neighbours of each particle.
%
% Depending on the interaction models adopted, a threshold distance is
% assumed for defining a neighbour (contact neighbours have a threshold
% distance of zero).
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <search_simpleloop.html Search_SimpleLoop> (default)
%
classdef Search < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of search algorithm
        SIMPLE_LOOP = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8   = uint8.empty;     % flag for type of search algorithm
        done logical = logical.empty;   % flag for identifying if search has been done in current time step
        
        % Parameters
        freq     uint32 = uint32.empty;   % search frequency (in steps)
        max_dist double = double.empty;   % threshold neighbour distance (exclusive) to create an interaction
        
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
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Search_SimpleLopp;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        execute(this,drv);
    end
end