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
        DISK = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8  = uint8.empty;    % flag for type of particle
        id   uint32 = uint32.empty;   % identification number
        
        % Geometric properties
        radius double = double.empty;
        
        % Physical properties
        material      Material = Material.empty;   % object of the Material class
        mass          double   = double.empty;     % mass (density * volume)
        weight        double   = double.empty;     % weight vector (mass * gravity)
        therm_inertia double   = double.empty;     % thermal inertia (mass * heat_capacity)
        
        % Neighbours Interactions
        interacts Interact  = Interact.empty;    % vector of objects of the Interact class
        
        % Current state
        coord       double = double.empty;   % coordinates of centroid
        orient      double = double.empty;   % orientation angles
        veloc_trl   double = double.empty;   % translational velocity
        veloc_rot   double = double.empty;   % rotational velocity
        accel_trl   double = double.empty;   % translational acceleration
        accel_rot   double = double.empty;   % rotational acceleration
        temperature double = double.empty;   % temperature
    end
    
    %% Constructor method
    methods
        function this = Particle(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
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