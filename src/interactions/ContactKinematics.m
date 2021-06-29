%% ContactKinematics class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef ContactKinematics < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of contact
        DISK_DISK = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type int8 = uint8.empty; % flag for type of contact
    end
    
    %% Constructor method
    methods
        function this = ContactKinematics(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactKinematics_DiskDisk;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end