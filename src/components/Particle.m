%% Particle class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Particle < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of particle
        DISK = 1;
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type = 0;   % flag for type of particle
        id   = 0;   % identification number
        
        % Geometric properties
        radius = 0;
        
        % Current state
        coord       = [];   % coordinates of centroid
        orient      = [];   % orientation angles
        veloc_trl   = [];   % translational velocity
        veloc_rot   = [];   % rotational velocity
        accel_trl   = [];   % translational acceleration
        accel_rot   = [];   % rotational acceleration
        temperature = 0;    % temperature
    end
    
    %% Constructor method
    methods
        function this = Particle(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Particle_Disk;
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