%% ConductionDirect (Direct Heat Conduction) class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of models
% for the direct heat conduction between elements.
%
% Direct heat conduction happens through the contact area of two touching
% bodies.
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <ConductionDirect_BOB.html ConductionDirect_BOB> (default)
% * <ConductionDirect_Pipe.html ConductionDirect_Pipe>
% * <ConductionDirect_Collisional.html ConductionDirect_Collisional>
%
classdef ConductionDirect < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        BOB         = uint8(1);
        PIPE        = uint8(3);
        COLLISIONAL = uint8(2);
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
        function this = ConductionDirect(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ConductionDirect_BOB;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        this = setDefaultProps(this);
        
        %------------------------------------------------------------------
        % Set parameters that are fixed throughout the whole analysis
        % (suposed to be called in thermal analysis).
        this = setFixParams(this,interact);
        
        %------------------------------------------------------------------
        % Set parameters that are constant over the interaction lifetime
        % (suposed to be called in thermomechanical analysis).
        this = setCteParams(this,interact);
        
        %------------------------------------------------------------------
        this = evalHeatRate(this,interact);
    end
end