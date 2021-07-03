%% ContactForceT (Tangential Contact Force) class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef ContactForceT < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        SPRING = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type int8 = uint8.empty;   % flag for type of model
        
        % Force results
        total_force double = double.empty;   % resulting force vector
    end
    
    %% Constructor method
    methods
        function this = ContactForceT(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactForceT_Spring;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        setParameters(this,interact);
        
        %------------------------------------------------------------------
        evalForce(this,interact);
    end
    
    %% Public methods
    methods
        
    end
end