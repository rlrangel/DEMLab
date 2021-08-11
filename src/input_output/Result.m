%% Result class
%
%% Description
%
% This is a handle class responsible for storing the required results.
%
% Each result type is stored in a separate array, which is initialized with
% NaN's (Not a Number).
%
classdef Result < handle
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of global parameters
        TIME = uint8(1);
        STEP = uint8(2);
        
        % Types of particle results: properties
        RADIUS = uint8(3);
        
        % Types of particle results: position
        MOTION       = uint8(4);
        COORDINATE_X = uint8(5);
        COORDINATE_Y = uint8(6);
        ORIENTATION  = uint8(7);
        
        % Types of particle results: forces
        FORCE_VEC = uint8(8);
        FORCE_MOD = uint8(9);
        FORCE_X   = uint8(10);
        FORCE_Y   = uint8(11);
        TORQUE    = uint8(12);
        
        % Types of particle results: velocity
        VELOCITY_VEC = uint8(13);
        VELOCITY_MOD = uint8(14);
        VELOCITY_X   = uint8(15);
        VELOCITY_Y   = uint8(16);
        VELOCITY_ROT = uint8(17);
        
        % Types of particle results: acceleration
        ACCELERATION_VEC = uint8(18);
        ACCELERATION_MOD = uint8(19);
        ACCELERATION_X   = uint8(20);
        ACCELERATION_Y   = uint8(21);
        ACCELERATION_ROT = uint8(22);
        
        % Types of particle results: thermal state
        HEAT_RATE   = uint8(23);
        TEMPERATURE = uint8(24);
    end
    
    %% Public properties: flags for required results
    properties (SetAccess = public, GetAccess = public)
        % Global parameters
        has_time = logical(false);
        has_step = logical(false);
        
        % Particle properties
        has_radius = logical(false);
        
        % Particle position
        has_coord_x     = logical(false);
        has_coord_y     = logical(false);
        has_orientation = logical(false);
        
        % Particle force
        has_force_x = logical(false);
        has_force_y = logical(false);
        has_torque  = logical(false);
        
        % Particle velocity
        has_velocity_x   = logical(false);
        has_velocity_y   = logical(false);
        has_velocity_rot = logical(false);
        
        % Particle acceleration
        has_acceleration_x   = logical(false);
        has_acceleration_y   = logical(false);
        has_acceleration_rot = logical(false);
        
        % Particle thermal state
        has_heat_rate   = logical(false);
        has_temperature = logical(false);
        
        % Wall state
        has_wall_position    = logical(false);
        has_wall_temperature = logical(false);
    end
    
    %% Public properties: results storage
    properties (SetAccess = public, GetAccess = public)
        % Index for columns (current output step)
        idx uint32 = uint32.empty;
        
        % Global parameters
        times double = double.empty;
        steps double = double.empty;
        
        % Particle properties
        radius double = double.empty;
        
        % Particle position
        coord_x     double = double.empty;
        coord_y     double = double.empty;
        orientation double = double.empty;
        
        % Particle force
        force_x double = double.empty;
        force_y double = double.empty;
        torque  double = double.empty;
        
        % Particle velocity
        velocity_x   double = double.empty;
        velocity_y   double = double.empty;
        velocity_rot double = double.empty;
        
        % Particle acceleration
        acceleration_x   double = double.empty;
        acceleration_y   double = double.empty;
        acceleration_rot double = double.empty;
        
        % Particle thermal state
        heat_rate   double = double.empty;
        temperature double = double.empty;
        
        % Wall state
        wall_position    double = double.empty;
        wall_temperature double = double.empty;
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
            % Index for columns
            this.idx = 1;
            
            % Number of columns: number of output steps (+initial conditions)
            c = drv.nout+1; 
            
            % Global parameters
            if (this.has_time)
                this.times = nan(1,c);
            end
            if (this.has_step)
                this.steps = nan(1,c);
            end
            
            % Number of rows for particles: total number of particles
            r = drv.n_particles;
            
            % Particle properties
            if (this.has_radius)
                this.radius = nan(r,c);
            end
            
            % Particle force
            if (this.has_force_x)
                this.force_x = nan(r,c);
            end
            if (this.has_force_y)
                this.force_y = nan(r,c);
            end
            if (this.has_torque)
                this.torque = nan(r,c);
            end
            
            % Particle position
            if (this.has_coord_x)
                this.coord_x = nan(r,c);
            end
            if (this.has_coord_y)
                this.coord_y = nan(r,c);
            end
            if (this.has_orientation)
                this.orientation = nan(r,c);
            end
            
            % Particle velocity
            if (this.has_velocity_x)
                this.velocity_x = nan(r,c);
            end
            if (this.has_velocity_y)
                this.velocity_y = nan(r,c);
            end
            if (this.has_velocity_rot)
                this.velocity_rot = nan(r,c);
            end
            
            % Particle acceleration
            if (this.has_acceleration_x)
                this.acceleration_x = nan(r,c);
            end
            if (this.has_acceleration_y)
                this.acceleration_y = nan(r,c);
            end
            if (this.has_acceleration_rot)
                this.acceleration_rot = nan(r,c);
            end
            
            % Particle thermal state
            if (this.has_heat_rate)
                this.heat_rate = nan(r,c);
            end
            if (this.has_temperature)
                this.temperature = nan(r,c);
            end
            
            % Number of rows for walls: total number of walls
            r = drv.n_walls;
            
            % Wall state
            if (this.has_wall_position)
                % 4 values for each wall in any column:
                % * Line wall:   x1,y1,x2,y2
                % * Circle wall: x,y,R,nan
                this.wall_position = nan(4*r,c);
            end
            if (this.has_wall_temperature)
                this.wall_temperature = nan(r,c);
            end
        end
        
        %------------------------------------------------------------------
        function updateIndex(this)
            this.idx = this.idx + 1;
        end
        
        %------------------------------------------------------------------
        function storeTime(this,drv)
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
        function storeParticlePositionAll(this,p)
            r = p.id;
            if (this.has_coord_x)
                this.coord_x(r,:) = p.coord(1);
            end
            if (this.has_coord_y)
                this.coord_y(r,:) = p.coord(2);
            end
            if (this.has_orientation)
                this.orientation(r,:) = p.orient;
            end
        end
        
        %------------------------------------------------------------------
        function storeParticleForce(this,p)
            r = p.id;
            c = this.idx;
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
        function storeParticleMotion(this,p)
            r = p.id;
            c = this.idx;
            if (this.has_velocity_x)
                this.velocity_x(r,c) = p.veloc_trl(1);
            end
            if (this.has_velocity_y)
                this.velocity_y(r,c) = p.veloc_trl(2);
            end
            if (this.has_velocity_rot)
                this.velocity_rot(r,c) = p.veloc_rot;
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
        function storeParticleTemperature(this,p)
            r = p.id;
            c = this.idx;
            if (this.has_temperature)
                this.temperature(r,c) = p.temperature;
            end
        end
        
        %------------------------------------------------------------------
        function storeParticleHeatRate(this,p)
            r = p.id;
            c = this.idx;
            if (this.has_heat_rate)
                this.heat_rate(r,c) = p.heat_rate;
            end
        end
        
        %------------------------------------------------------------------
        function storeWallPosition(this,w)
            r = 4 * (w.id-1) + 1;
            c = this.idx;
            if (this.has_wall_position)
                if (w.type == w.LINE)
                    this.wall_position(r+0,c) = w.coord_ini(1);
                    this.wall_position(r+1,c) = w.coord_ini(2);
                    this.wall_position(r+2,c) = w.coord_end(1);
                    this.wall_position(r+3,c) = w.coord_end(2);
                elseif (w.type == w.CIRCLE)
                    this.wall_position(r+0,c) = w.center(1);
                    this.wall_position(r+1,c) = w.center(2);
                    this.wall_position(r+2,c) = w.radius;
                end
            end
        end
        
        %------------------------------------------------------------------
        function storeWallPositionAll(this,w)
            r = 4 * (w.id-1) + 1;
            if (this.has_wall_position)
                if (w.type == w.LINE)
                    this.wall_position(r+0,:) = w.coord_ini(1);
                    this.wall_position(r+1,:) = w.coord_ini(2);
                    this.wall_position(r+2,:) = w.coord_end(1);
                    this.wall_position(r+3,:) = w.coord_end(2);
                elseif (w.type == w.CIRCLE)
                    this.wall_position(r+0,:) = w.center(1);
                    this.wall_position(r+1,:) = w.center(2);
                    this.wall_position(r+2,:) = w.radius;
                end
            end
        end
        
        %------------------------------------------------------------------
        function storeWallTemperature(this,w)
            r = w.id;
            c = this.idx;
            if (this.has_wall_temperature && ~w.adiabatic)
                this.wall_temperature(r,c) = w.temperature;
            end
        end
    end
end