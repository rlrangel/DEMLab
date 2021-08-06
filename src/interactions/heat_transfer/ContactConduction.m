%% ContactConduction class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of models
% for the contact heat conduction between elements.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <contactconduction_bob.html ContactConduction_BOB> (default)
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
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactConduction_BOB;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        this = setDefaultProps(this);
        
        %------------------------------------------------------------------
        this = evalHeatRate(this,interact);
    end
end