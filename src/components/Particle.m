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
        SPHERE   = uint8(1);
        CYLINDER = uint8(2);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8  = uint8.empty;    % flag for type of particle
        id   uint32 = uint32.empty;   % identification number
        
        % Geometric properties
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
        
        % Prescribed conditions (handles to objects of Cond class)
        pc_force    Cond = Cond.empty;
        pc_torque   Cond = Cond.empty;
        pc_heatflux Cond = Cond.empty;
        pc_heatrate Cond = Cond.empty;
        
        % Fixed conditions (handles to objects of Cond class)
        fc_translation Cond = Cond.empty;
        fc_rotation    Cond = Cond.empty;
        fc_temperature Cond = Cond.empty;
        
        % Flags for free/fixed particles
        free_trl   logical = logical.empty;   % flag for translational free particle
        free_rot   logical = logical.empty;   % flag for rotational free particle
        free_therm logical = logical.empty;   % flag for thermally free particle
        
        % Total forcing terms
        force     double = double.empty;
        torque    double = double.empty;
        heat_rate double = double.empty;
        
        % Current mechanical state
        coord     double = double.empty;   % coordinates of centroid
        orient    double = double.empty;   % orientation angle
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
        function resetForcingTerms(this)
            this.force     = [0;0];
            this.torque    = 0;
            this.heat_rate = 0;
        end
        
        %------------------------------------------------------------------
        function addWeight(this)
            if (~isempty(this.weight))
                this.force = this.force + this.weight;
            end
        end
        
        %------------------------------------------------------------------
        function addGblDampTransl(this,damp_coeff)
            this.force = this.force - damp_coeff * this.veloc_trl;
        end
        
        %------------------------------------------------------------------
        function addGblDampRot(this,damp_coeff)
            this.torque = this.torque - damp_coeff * this.veloc_rot;
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
        function setFreeMech(this,time)
            this.free_trl = true;
            this.free_rot = true;
            for i = 1:length(this.fc_translation)
                if (this.fc_translation(i).isActive(time))
                    this.free_trl = false;
                    break;
                end
            end
            for i = 1:length(this.fc_rotation)
                if (this.fc_rotation(i).isActive(time))
                    this.free_rot = false;
                    break;
                end
            end
        end
        
        %------------------------------------------------------------------
        function setFreeTherm(this,time)
            this.free_therm = true;
            for i = 1:length(this.fc_temperature)
                if (this.fc_temperature(i).isActive(time))
                    this.free_therm = false;
                    return;
                end
            end
        end
        
        %------------------------------------------------------------------
        function setFCTranslation(this,time,dt)
            if (this.free_trl)
                if (~this.free_rot)
                    this.accel_trl = [0;0];
                    this.veloc_trl = [0;0];
                    this.coord     =  this.coord;
                end
            else
                vel = [0;0];
                for i = 1:length(this.fc_translation)
                    if (this.fc_translation(i).isActive(time))
                        vel = vel + this.fc_translation(i).getValue(time);
                    end
                end
                this.accel_trl = (vel-this.veloc_trl) / dt;
                this.veloc_trl =  vel;
                this.coord     =  this.coord + vel * dt;
            end
        end
        
        %------------------------------------------------------------------
        function setFCRotation(this,time,dt)
            if (this.free_rot)
                if (~this.free_trl)
                    this.accel_rot = 0;
                    this.veloc_rot = 0;
                    this.orient    =  this.orient;
                end
            else
                vel = 0;
                for i = 1:length(this.fc_rotation)
                    if (this.fc_rotation(i).isActive(time))
                        vel = vel + this.fc_rotation(i).getValue(time);
                    end
                end
                this.accel_rot = (vel-this.veloc_trl) / dt;
                this.veloc_rot =  vel;
                this.orient    =  this.orient + vel * dt;
            end
        end
        
        %------------------------------------------------------------------
        function setFCTemperature(this,time)
            if (this.free_therm)
                return;
            end
            for i = 1:length(this.fc_temperature)
                if (this.fc_temperature(i).isActive(time))
                    this.temperature = this.fc_temperature(i).getValue(time);
                end
            end
        end
        
        %------------------------------------------------------------------
        function setAccelTrl(this)
            this.accel_trl = this.force / this.mass;
        end
        
        %------------------------------------------------------------------
        function setAccelRot(this)
            this.accel_rot = this.torque / this.minertia;
        end
        
        %------------------------------------------------------------------
        function setTempChange(this)
            this.temp_change = this.heat_rate / this.tinertia;
        end
    end
end