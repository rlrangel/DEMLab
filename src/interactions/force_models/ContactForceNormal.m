%% ContactForceNormal class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef ContactForceNormal < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        DISK_DISK_VISCOELASTIC_LINEAR = uint8(1);
        
        % Types of stiffness formulation
        NONE    = uint8(1);
        TIME    = uint8(2);
        OVERLAP = uint8(3);
        ENERGY  = uint8(4);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type int8 = uint8.empty; % flag for type of model
    end
    
    %% Constructor method
    methods
        function this = ContactForceNormal(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactForceNormal_DiskDisk_LinearViscoElastic;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        applyDefaultProps(this);
    end
    
    %% Public methods
    methods
        
    end
end