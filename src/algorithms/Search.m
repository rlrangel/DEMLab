%% Search class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Search < handle
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of search
        SIMPLE_LOOP = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type int8 = uint8.empty;   % flag for type of search
    end
    
    %% Constructor method
    methods
        function this = Search(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end