%% ContactForceTangent class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef ContactForceTangent < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        DISK_DISK_SPRING = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type int8 = uint8.empty; % flag for type of model
    end
    
    %% Constructor method
    methods
        function this = ContactForceTangent(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactForceTangent_DiskDisk_Spring;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end