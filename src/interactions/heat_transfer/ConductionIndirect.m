%% ConductionDirect class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of models
% for the indirect heat conduction between elements.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
classdef ConductionIndirect < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = ConductionIndirect(type)
            
        end
    end
    
    %% Default sub-class definition
    
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        this = setDefaultProps(this);
        
        %------------------------------------------------------------------
        this = setCteParams(this,interact);
        
        %------------------------------------------------------------------
        this = evalHeatRate(this,interact);
    end
end