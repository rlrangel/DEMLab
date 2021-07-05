%% Result class
%
%% Description
%
%% Implementation
%
classdef Result < handle
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of global parameters
        TIME = uint8(1);
        STEP = uint8(2);
        
        % Types of particle results: properties
        RADIUS = uint8(3);
        
        % Types of particle results: forces
        FORCE_MOD = uint8(4);
        FORCE_X   = uint8(5);
        FORCE_Y   = uint8(6);
        TORQUE    = uint8(7);
        
        % Types of particle results: position
        COORDINATE_X = uint8(8);
        COORDINATE_Y = uint8(9);
        ORIENTATION  = uint8(10);
        
        % Types of particle results: motion
        MOTION           = uint8(11);
        VELOCITY_MOD     = uint8(12);
        VELOCITY_X       = uint8(13);
        VELOCITY_Y       = uint8(14);
        VELOCITY_ROT     = uint8(15);
        ACCELERATION_MOD = uint8(16);
        ACCELERATION_X   = uint8(17);
        ACCELERATION_Y   = uint8(18);
        ACCELERATION_ROT = uint8(19);
        
        % Types of particle results: thermal state
        HEAT_RATE   = uint8(20);
        TEMPERATURE = uint8(21);
    end
    
    %% Public properties: Flags for required results
    properties (SetAccess = public, GetAccess = public)
        % Global parameters
        has_time = logical(false);
        has_step = logical(false);
        
        % Properties results
        has_radius = logical(false);
        
        % Force results
        has_force_mod = logical(false);
        has_force_x   = logical(false);
        has_force_y   = logical(false);
        has_torque    = logical(false);
        
        % Position results
        has_coord_x     = logical(false);
        has_coord_y     = logical(false);
        has_orientation = logical(false);
        
        % Motion results
        has_velocity_mod     = logical(false);
        has_velocity_x       = logical(false);
        has_velocity_y       = logical(false);
        has_velocity_rot     = logical(false);
        has_acceleration_mod = logical(false);
        has_acceleration_x   = logical(false);
        has_acceleration_y   = logical(false);
        has_acceleration_rot = logical(false);
        
        % Thermal state results
        has_heat_rate   = logical(false);
        has_temperature = logical(false);
    end
    
    %% Public properties: Results storage
    properties (SetAccess = public, GetAccess = public)
        % Index for columns (current output step)
        idx uint32 = uint32.empty;
        
        % Global parameters
        times double = double.empty;
        steps double = double.empty;
        
        % Properties results
        radius double = double.empty;
        
        % Force results
        force_mod double = double.empty
        force_x   double = double.empty
        force_y   double = double.empty
        torque    double = double.empty
        
        % Position results
        coord_x     double = double.empty
        coord_y     double = double.empty
        orientation double = double.empty
        
        % Motion results
        velocity_mod     double = double.empty
        velocity_x       double = double.empty
        velocity_y       double = double.empty
        velocity_rot     double = double.empty
        acceleration_mod double = double.empty
        acceleration_x   double = double.empty
        acceleration_y   double = double.empty
        acceleration_rot double = double.empty
        
        % Thermal state results
        heat_rate   double = double.empty
        temperature double = double.empty
    end
    
    %% Constructor method
    methods
        function this = Result()
            
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function initialize(this,drv)
            % Number of rows and columns
            r = drv.n_particles;   % rows: total number of particles
            c = drv.nout+1;        % columns: number of output steps (+initial conditions)
            
            % Index for columns
            this.idx = 1;
            
            % Global parameters
            if (this.has_time)
                this.times = nan(1,c);
            end
            if (this.has_step)
                this.steps = nan(1,c);
            end
            
            % Properties results
            if (this.has_radius)
                this.radius = nan(r,1);
            end
            
            % Force results
            if (this.has_force_mod)
                this.force_mod = nan(r,c);
            end
            if (this.has_force_x)
                this.force_x = nan(r,c);
            end
            if (this.has_force_y)
                this.force_y = nan(r,c);
            end
            if (this.has_torque)
                this.torque = nan(r,c);
            end
            
            % Position results
            if (this.has_coord_x)
                this.coord_x = nan(r,c);
            end
            if (this.has_coord_y)
                this.coord_y = nan(r,c);
            end
            if (this.has_orientation)
                this.orientation = nan(r,c);
            end
            
            % Motion results
            if (this.has_velocity_mod)
                this.velocity_mod = nan(r,c);
            end
            if (this.has_velocity_x)
                this.velocity_x = nan(r,c);
            end
            if (this.has_velocity_y)
                this.velocity_y = nan(r,c);
            end
            if (this.has_velocity_rot)
                this.velocity_rot = nan(r,c);
            end
            if (this.has_acceleration_mod)
                this.acceleration_mod = nan(r,c);
            end
            if (this.has_acceleration_x)
                this.acceleration_x = nan(r,c);
            end
            if (this.has_acceleration_y)
                this.acceleration_y = nan(r,c);
            end
            if (this.has_acceleration_rot)
                this.acceleration_rot = nan(r,c);
            end
            
            % Thermal state results
            if (this.has_heat_rate)
                this.heat_rate = nan(r,c);
            end
            if (this.has_temperature)
                this.temperature = nan(r,c);
            end
        end
        
        %------------------------------------------------------------------
        function updateIndex(this)
            this.idx = this.idx + 1;
        end
        
        %------------------------------------------------------------------
        function storeGlobalParams(this,drv)
            c = this.idx;
            if (this.has_time)
                this.times(c) = drv.time;
            end
            if (this.has_step)
                this.steps(c) = drv.step;
            end
        end
        
        %------------------------------------------------------------------
        function storeParticleProp(this,p)
            if (this.has_radius)
                this.radius(p.id,:) = p.radius;
            end
        end
        
        %------------------------------------------------------------------
        function storeParticleForce(this,p)
            r = p.id;
            c = this.idx;
            if (this.has_force_mod)
                this.force_mod(r,c) = norm(p.force);
            end
            if (this.has_force_x)
                this.force_x(r,c) = p.force(1);
            end
            if (this.has_force_y)
                this.force_y(r,c) = p.force(2);
            end
            if (this.has_torque)
                this.torque(r,c) = p.torque;
            end
        end
        
        %------------------------------------------------------------------
        function storeParticlePosition(this,p)
            r = p.id;
            c = this.idx;
            if (this.has_coord_x)
                this.coord_x(r,c) = p.coord(1);
            end
            if (this.has_coord_y)
                this.coord_y(r,c) = p.coord(2);
            end
            if (this.has_orientation)
                this.orientation(r,c) = p.orient;
            end
        end
        
        %------------------------------------------------------------------
        function storeParticleMotion(this,p)
            r = p.id;
            c = this.idx;
            if (this.has_velocity_mod)
                this.velocity_mod(r,c) = norm(p.veloc_trl);
            end
            if (this.has_velocity_x)
                this.velocity_x(r,c) = p.veloc_trl(1);
            end
            if (this.has_velocity_y)
                this.velocity_y(r,c) = p.veloc_trl(2);
            end
            if (this.has_velocity_rot)
                this.velocity_rot(r,c) = p.veloc_rot;
            end
            if (this.has_acceleration_mod)
                this.acceleration_mod(r,c) = norm(p.accel_trl);
            end
            if (this.has_acceleration_x)
                this.acceleration_x(r,c) = p.accel_trl(1);
            end
            if (this.has_acceleration_y)
                this.acceleration_y(r,c) = p.accel_trl(2);
            end
            if (this.has_acceleration_rot)
                this.acceleration_rot(r,c) = p.accel_rot;
            end
        end
        
        %------------------------------------------------------------------
        function storeParticleThermal(this,p)
            r = p.id;
            c = this.idx;
            if (this.has_temperature)
                this.temperature(r,c) = p.temperature;
            end
            if (this.has_heat_rate)
                this.heat_rate(r,c) = p.heat_rate;
            end
        end
    end
end