%% RollResist (Rolling Resistance) class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of models
% for the rolling resistance torque between elements.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <rollresist_constanta.html RollResist_Constant> (default)
%
classdef RollResist < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        CONSTANT = uint8(1);
        VISCOUS  = uint8(2);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of model
        
        % Force results
        torque double = double.empty;   % resulting rolling resistance torque
    end
    
    %% Constructor method
    methods
        function this = RollResist(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = RollResist_ConstantA;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        this = setDefaultProps(this);
        
        %------------------------------------------------------------------
        this = setParameters(this,interact);
        
        %------------------------------------------------------------------
        this = evalTorque(this,interact);
    end
end