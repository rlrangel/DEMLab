%% Particle class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of
% particles.
%
% In DEM, particles are assumed to be soft, so that contact forces and heat
% exchange are originated by overlaps.
% Furthermore, their shapes are assumed to be preserved after collisions.
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <particle_sphere.html Particle_Sphere> (default)
% * <particle_cylinder.html Particle_Cylinder>
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
        cross    double = double.empty;   % in-plane cross-sectional area
        volume   double = double.empty;   % volume
        minertia double = double.empty;   % moment of inertia
        
        % Physical properties
        material Material = Material.empty;   % handle to object of Material_Solid subclass
        mass     double   = double.empty;     % mass (density * volume)
        weight   double   = double.empty;     % weight vector (mass * gravity)
        tinertia double   = double.empty;     % thermal inertia (mass * heat_capacity)
        
        % Neighbours Interactions
        interacts Interact = Interact.empty;   % handles to objects of Interact class
        verlet_p  Particle = Particle.empty;   % handles to objects of Particle class in the verlet list
        verlet_w  Wall     = Wall.empty;       % handles to objects of Wall class in the verlet list
        neigh_p   uint32   = uint32.empty;     % vector of neighbours particles IDs
        neigh_w   uint32   = uint32.empty;     % vector of neighbours walls IDs
        porosity  double   = double.empty;     % average porosity (void ratio) around particle
        por_freq  double   = double.empty;     % average porosity update frequency (in steps) (double to accept NaN)
        
        % Behavior flags
        free_trl   logical = logical.empty;   % flag for translational free particle
        free_rot   logical = logical.empty;   % flag for rotational free particle
        free_therm logical = logical.empty;   % flag for thermally free particle
        
        % Prescribed conditions (handles to objects of Condition class)
        pc_force    Condition = Condition.empty;
        pc_torque   Condition = Condition.empty;
        pc_heatflux Condition = Condition.empty;
        pc_heatrate Condition = Condition.empty;
        
        % Fixed conditions (handles to objects of Condition class)
        fc_translation Condition = Condition.empty;
        fc_rotation    Condition = Condition.empty;
        fc_temperature Condition = Condition.empty;
        
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
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Particle_Sphere;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        setSurface(this);
        
        %------------------------------------------------------------------
        setCrossSec(this);
        
        %------------------------------------------------------------------
        setVolume(this);
        
        %------------------------------------------------------------------
        setMInertia(this);
        
        %------------------------------------------------------------------
        [x1,y1,x2,y2] = getBBoxLimits(this);
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
        function setFixedMech(this,time)
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
        function setFixedThermal(this,time)
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
                return;
            end
            v = [0;0];
            for i = 1:length(this.fc_translation)
                if (this.fc_translation(i).isActive(time))
                    v = v + this.fc_translation(i).getValue(time);
                end
            end
            this.accel_trl = (v-this.veloc_trl) / dt;
            this.veloc_trl =  v;
            this.coord     =  this.coord + v * dt;
        end
        
        %------------------------------------------------------------------
        function setFCRotation(this,time,dt)
            if (this.free_rot)
                return;
            end
            w = 0;
            for i = 1:length(this.fc_rotation)
                if (this.fc_rotation(i).isActive(time))
                    w = w + this.fc_rotation(i).getValue(time);
                end
            end
            this.accel_rot = (w-this.veloc_rot) / dt;
            this.veloc_rot =  w;
            this.orient    =  this.orient + w * dt;
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