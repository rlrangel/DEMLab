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
        radius   double = double.empty;
        surface  double = double.empty;
        volume   double = double.empty;
        minertia double = double.empty;
        
        % Physical properties
        material Material = Material.empty;   % object of the Material class
        mass     double   = double.empty;     % mass (density * volume)
        weight   double   = double.empty;     % weight vector (mass * gravity)
        tinertia double   = double.empty;     % thermal inertia (mass * heat_capacity)
        
        % Prescribed conditions (vectors of objects of the PC class)
        pc_forces     PC = PC.empty;
        pc_torques    PC = PC.empty;
        pc_heatfluxes PC = PC.empty;
        pc_heatrates  PC = PC.empty;
        
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
        
        %------------------------------------------------------------------
        setSurface(this);
        
        %------------------------------------------------------------------
        setVolume(this);
        
        %------------------------------------------------------------------
        setMInertia(this);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setMass(this)
            this.mass = this.volume * this.material.density;
        end
        
        %------------------------------------------------------------------
        function setWeight(this,g)
            this.weight = this.mass * g;
        end
        
        %------------------------------------------------------------------
        function setTInertia(this)
            this.tinertia = this.mass * this.material.hcapacity;
        end
    end
end