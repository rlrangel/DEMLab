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
        SPHERE = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8  = uint8.empty;    % flag for type of particle
        id   uint32 = uint32.empty;   % identification number
        
        % Geometric properties
        radius   double = double.empty;   % radius
        surface  double = double.empty;   % surface area
        volume   double = double.empty;   % volume
        minertia double = double.empty;   % moment of inertia
        
        % Physical properties
        material Material = Material.empty;   % handle to object of Material class
        mass     double   = double.empty;     % mass (density * volume)
        weight   double   = double.empty;     % weight vector (mass * gravity)
        tinertia double   = double.empty;     % thermal inertia (mass * heat_capacity)
        
        % Neighbours Interactions
        interacts Interact = Interact.empty;   % handles to objects of Interact class
        
        % Prescribed conditions (handles to objects of PC class)
        pc_force     PC = PC.empty;
        pc_torque    PC = PC.empty;
        pc_heatflux  PC = PC.empty;
        pc_heatrate  PC = PC.empty;
        
        % Fixed conditions (handles to objects of PC class)
        fc_temperature PC = PC.empty;
        
        % Total forcing terms
        force     double = double.empty;
        torque    double = double.empty;
        heat_rate double = double.empty;
        
        % Current mechanical state
        coord     double = double.empty;   % coordinates of centroid
        orient    double = double.empty;   % orientation angles
        veloc_trl double = double.empty;   % translational velocity
        veloc_rot double = double.empty;   % rotational velocity
        accel_trl double = double.empty;   % translational acceleration
        accel_rot double = double.empty;   % rotational acceleration
        
        % Current thermal state
        temperature double = double.empty;   % temperature
        temp_change double = double.empty;   % temperature rate of change
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
            defaultObject = Particle_Sphere;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        resetForcingTerms(this);
        
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
        
        %------------------------------------------------------------------
        function addWeight(this)
            if (~isempty(this.weight))
                this.force = this.force + this.weight;
            end
        end
        
        %------------------------------------------------------------------
        function addPCForce(this,time)
            for i = 1:length(this.pc_force)
                if (this.pc_force(i).isActive(time))
                    this.force = this.force + this.pc_force(i).getValue(time);
                end
            end
        end
        
        %------------------------------------------------------------------
        function addPCTorque(this,time)
            for i = 1:length(this.pc_torque)
                if (this.pc_torque(i).isActive(time))
                    this.torque = this.torque + this.pc_torque(i).getValue(time);
                end
            end
        end
        
        %------------------------------------------------------------------
        function addPCHeatFlux(this,time)
            for i = 1:length(this.pc_heatflux)
                if (this.pc_heatflux(i).isActive(time))
                    hr = this.pc_heatflux(i).getValue(time) * this.surface;
                    this.heat_rate = this.heat_rate + hr;
                end
            end
        end
        
        %------------------------------------------------------------------
        function addPCHeatRate(this,time)
            for i = 1:length(this.pc_heatrate)
                if (this.pc_heatrate(i).isActive(time))
                    this.heat_rate = this.heat_rate + this.pc_heatrate(i).getValue(time);
                end
            end
        end
        
        %------------------------------------------------------------------
        function setFCTemperature(this,time)
            for i = 1:length(this.fc_temperature)
                if (this.fc_temperature(i).isActive(time))
                    this.temperature = this.fc_temperature(i).getValue(time);
                end
            end
        end
        
        %------------------------------------------------------------------
        function computeAccelTrl(this)
            this.accel_trl = this.force / this.mass;
        end
        
        %------------------------------------------------------------------
        function computeAccelRot(this)
            this.accel_rot = this.torque / this.minertia;
        end
        
        %------------------------------------------------------------------
        function computeTempChange(this)
            this.temp_change = this.heat_rate / this.tinertia;
        end
    end
end