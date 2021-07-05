%% ContactConduction class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef ContactConduction < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        BATCHELOR_OBRIEN = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of model
        
        % Heat rate results
        total_hrate double = double.empty;   % resulting heat rate
    end
    
    %% Constructor method
    methods
        function this = ContactConduction(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactConduction_BOB;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        this = setParameters(this,interact);
        
        %------------------------------------------------------------------
        this = evalHeatRate(this,interact);
    end
    
    %% Public methods
    methods
        
    end
end