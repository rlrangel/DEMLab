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
        %--------------------------------------
        % Types of global parameters:
        TIME = uint8(1);
        STEP = uint8(2);
        
        %--------------------------------------
        % Types of individual particle results:
        
        % Properties
        RADIUS = uint8(3);
        MASS   = uint8(4);
        
        % Position
        MOTION       = uint8(5);
        COORDINATE_X = uint8(6);
        COORDINATE_Y = uint8(7);
        ORIENTATION  = uint8(8);
        
        % Force
        FORCE_VEC = uint8(9);
        FORCE_MOD = uint8(10);
        FORCE_X   = uint8(11);
        FORCE_Y   = uint8(12);
        TORQUE    = uint8(13);
        
        % Velocity
        VELOCITY_VEC = uint8(14);
        VELOCITY_MOD = uint8(15);
        VELOCITY_X   = uint8(16);
        VELOCITY_Y   = uint8(17);
        VELOCITY_ROT = uint8(18);
        
        % Acceleration
        ACCELERATION_VEC = uint8(19);
        ACCELERATION_MOD = uint8(20);
        ACCELERATION_X   = uint8(21);
        ACCELERATION_Y   = uint8(22);
        ACCELERATION_ROT = uint8(23);
        
        % Thermal
        HEAT_RATE   = uint8(24);
        TEMPERATURE = uint8(25);
        
        %--------------------------------------
        % Types of average particle results:
        AVG_VELOCITY_MOD     = uint8(26);
        AVG_VELOCITY_ROT     = uint8(27);
        AVG_ACCELERATION_MOD = uint8(28);
        AVG_ACCELERATION_ROT = uint8(29);
        AVG_TEMPERATURE      = uint8(30);
        
        %--------------------------------------
        % Types of extreme particle results:
        MIN_VELOCITY_MOD     = uint8(31);
        MAX_VELOCITY_MOD     = uint8(32);
        MIN_VELOCITY_ROT     = uint8(33);
        MAX_VELOCITY_ROT     = uint8(34);
        MIN_ACCELERATION_MOD = uint8(35);
        MAX_ACCELERATION_MOD = uint8(36);
        MIN_ACCELERATION_ROT = uint8(37);
        MAX_ACCELERATION_ROT = uint8(38);
        MIN_TEMPERATURE      = uint8(39);
        MAX_TEMPERATURE      = uint8(40);
        
        %--------------------------------------
        % Types of total interaction results:
        TOT_HEAT_RATE_ALL       = uint8(41);
        TOT_CONDUCTION_DIRECT   = uint8(42);
        TOT_CONDUCTION_INDIRECT = uint8(43);
    end
    
    %% Public properties: flags for required results
    properties (SetAccess = public, GetAccess = public)
        %--------------------------------------
        % Global parameters:
        has_time = logical(false);
        has_step = logical(false);
        
        %--------------------------------------
        % Individual particle results:
        
        % Properties
        has_radius = logical(false);
        has_mass   = logical(false);
        
        % Position
        has_coord_x     = logical(false);
        has_coord_y     = logical(false);
        has_orientation = logical(false);
        
        % Force
        has_force_x = logical(false);
        has_force_y = logical(false);
        has_torque  = logical(false);
        
        % Velocity
        has_velocity_x   = logical(false);
        has_velocity_y   = logical(false);
        has_velocity_rot = logical(false);
        
        % Acceleration
        has_acceleration_x   = logical(false);
        has_acceleration_y   = logical(false);
        has_acceleration_rot = logical(false);
        
        % Thermal
        has_heat_rate   = logical(false);
        has_temperature = logical(false);
        
        %--------------------------------------
        % Average particle results:
        has_avg_velocity_mod     = logical(false);
        has_avg_velocity_rot     = logical(false);
        has_avg_acceleration_mod = logical(false);
        has_avg_acceleration_rot = logical(false);
        has_avg_temperature      = logical(false);
        
        %--------------------------------------
        % Extreme particle results:
        has_min_velocity_mod     = logical(false);
        has_max_velocity_mod     = logical(false);
        has_min_velocity_rot     = logical(false);
        has_max_velocity_rot     = logical(false);
        has_min_acceleration_mod = logical(false);
        has_max_acceleration_mod = logical(false);
        has_min_acceleration_rot = logical(false);
        has_max_acceleration_rot = logical(false);
        has_min_temperature      = logical(false);
        has_max_temperature      = logical(false);
        
        %--------------------------------------
        % Total interaction results:
        has_tot_heat_rate_all       = logical(false);
        has_tot_conduction_direct   = logical(false);
        has_tot_conduction_indirect = logical(false);
        
        %--------------------------------------
        % Wall results:
        has_wall_position    = logical(false);
        has_wall_temperature = logical(false);
    end
    
    %% Public properties: results storage
    properties (SetAccess = public, GetAccess = public)
        % Index for columns (current output step)
        idx uint32 = uint32.empty;
        
        %--------------------------------------
        % Global parameters:
        times double = double.empty;
        steps double = double.empty;
        
        %--------------------------------------
        % Individual particle results:
        
        % Properties
        radius double = double.empty;
        mass   double = double.empty;
        
        % Position
        coord_x     double = double.empty;
        coord_y     double = double.empty;
        orientation double = double.empty;
        
        % Force
        force_x double = double.empty;
        force_y double = double.empty;
        torque  double = double.empty;
        
        % Velocity
        velocity_x   double = double.empty;
        velocity_y   double = double.empty;
        velocity_rot double = double.empty;
        
        % Acceleration
        acceleration_x   double = double.empty;
        acceleration_y   double = double.empty;
        acceleration_rot double = double.empty;
        
        % Thermal
        heat_rate   double = double.empty;
        temperature double = double.empty;
        
        %--------------------------------------
        % Average particle results:
        avg_velocity_mod     double = double.empty;
        avg_velocity_rot     double = double.empty;
        avg_acceleration_mod double = double.empty;
        avg_acceleration_rot double = double.empty;
        avg_temperature      double = double.empty;
        
        %--------------------------------------
        % Extreme particle results:
        min_velocity_mod     double = double.empty;
        max_velocity_mod     double = double.empty;
        min_velocity_rot     double = double.empty;
        max_velocity_rot     double = double.empty;
        min_acceleration_mod double = double.empty;
        max_acceleration_mod double = double.empty;
        min_acceleration_rot double = double.empty;
        max_acceleration_rot double = double.empty;
        min_temperature      double = double.empty;
        max_temperature      double = double.empty;
        
        %--------------------------------------
        % Total interactions results:
        tot_heat_rate_all       double = double.empty;
        tot_conduction_direct   double = double.empty;
        tot_conduction_indirect double = double.empty;
        
        %--------------------------------------
        % Wall results:
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
            
            % Number of columns for all results: number of output steps (+initial conditions)
            c = drv.nout+1; 
            
            % Number of rows for individual particle results: total number of particles
            rp = drv.n_particles;
            
            % Number of rows for individual wall results: total number of walls
            rw = drv.n_walls;
            
            % Set results that always need to be stored to show model
            this.has_time          = true;
            this.has_coord_x       = true;
            this.has_coord_y       = true;
            this.has_radius        = true;
            this.has_wall_position = true;
            if (drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL)
                this.has_temperature      = true;
                this.has_wall_temperature = true;
            end
            
            %--------------------------------------
            % Global parameters:
            if (this.has_time)
                this.times = nan(1,c);
            end
            if (this.has_step)
                this.steps = nan(1,c);
            end
            
            %--------------------------------------
            % Individual particle results:
            
            % Properties
            if (this.has_radius)
                this.radius = nan(rp,c);
            end
            if (this.has_mass)
                this.mass = nan(rp,c);
            end
            
            % Force
            if (this.has_force_x)
                this.force_x = nan(rp,c);
            end
            if (this.has_force_y)
                this.force_y = nan(rp,c);
            end
            if (this.has_torque)
                this.torque = nan(rp,c);
            end
            
            % Position
            if (this.has_coord_x)
                this.coord_x = nan(rp,c);
            end
            if (this.has_coord_y)
                this.coord_y = nan(rp,c);
            end
            if (this.has_orientation)
                this.orientation = nan(rp,c);
            end
            
            % Velocity
            if (this.has_velocity_x)
                this.velocity_x = nan(rp,c);
            end
            if (this.has_velocity_y)
                this.velocity_y = nan(rp,c);
            end
            if (this.has_velocity_rot)
                this.velocity_rot = nan(rp,c);
            end
            
            % Acceleration
            if (this.has_acceleration_x)
                this.acceleration_x = nan(rp,c);
            end
            if (this.has_acceleration_y)
                this.acceleration_y = nan(rp,c);
            end
            if (this.has_acceleration_rot)
                this.acceleration_rot = nan(rp,c);
            end
            
            % Thermal
            if (this.has_heat_rate)
                this.heat_rate = nan(rp,c);
            end
            if (this.has_temperature)
                this.temperature = nan(rp,c);
            end
            
            %--------------------------------------
            % Average particle results:
            if (this.has_avg_velocity_mod)
                this.avg_velocity_mod = nan(1,c);
            end
            if (this.has_avg_velocity_rot)
                this.avg_velocity_rot = nan(1,c);
            end
            if (this.has_avg_acceleration_mod)
                this.avg_acceleration_mod = nan(1,c);
            end
            if (this.has_avg_acceleration_rot)
                this.avg_acceleration_rot = nan(1,c);
            end
            if (this.has_avg_temperature)
                this.avg_temperature = nan(1,c);
            end
            
            %--------------------------------------
            % Extreme particle results:
            if (this.has_min_velocity_mod)
                this.min_velocity_mod = nan(1,c);
            end
            if (this.has_max_velocity_mod)
                this.max_velocity_mod = nan(1,c);
            end
            if (this.has_min_velocity_rot)
                this.min_velocity_rot = nan(1,c);
            end
            if (this.has_max_velocity_rot)
                this.max_velocity_rot = nan(1,c);
            end
            if (this.has_min_acceleration_mod)
                this.min_acceleration_mod = nan(1,c);
            end
            if (this.has_max_acceleration_mod)
                this.max_acceleration_mod = nan(1,c);
            end
            if (this.has_min_acceleration_rot)
                this.min_acceleration_rot = nan(1,c);
            end
            if (this.has_max_acceleration_rot)
                this.max_acceleration_rot = nan(1,c);
            end
            if (this.has_min_temperature)
                this.min_temperature = nan(1,c);
            end
            if (this.has_max_temperature)
                this.max_temperature = nan(1,c);
            end
            
            %--------------------------------------
            % Total particle results:
            if (this.has_tot_heat_rate_all)
                this.tot_heat_rate_all = nan(1,c);
            end
            if (this.has_tot_conduction_direct)
                this.tot_conduction_direct = nan(1,c);
            end
            if (this.has_tot_conduction_indirect)
                this.tot_conduction_indirect = nan(1,c);
            end
            
            %--------------------------------------
            % Wall results:
            
            % Position
            if (this.has_wall_position)
                % 4 values for each wall in any column:
                % * Line wall:   x1,y1,x2,y2
                % * Circle wall: x,y,R,nan
                this.wall_position = nan(4*rw,c);
            end
            
            % Thermal
            if (this.has_wall_temperature)
                this.wall_temperature = nan(rw,c);
            end
        end
        
        %------------------------------------------------------------------
        function updateIndex(this)
            % Do not allow column index to be greater than the number of
            % output steps to avoid erros accessing the results arrays
            % (number of output steps = preallocated size of times vector)
            this.idx = min(this.idx+1,length(this.times));
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
        % Fixed properties for all steps
        function storeParticleProp(this,p)
            if (this.has_radius)
                this.radius(p.id,:) = p.radius;
            end
            if (this.has_mass)
                this.mass(p.id,:) = p.mass;
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
        function storeParticleVelocity(this,p)
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
        end
        
        %------------------------------------------------------------------
        function storeParticleAcceleration(this,p)
            r = p.id;
            c = this.idx;
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
        function storeAvgVelocity(this,drv)
            c = this.idx;
            if (this.has_avg_velocity_mod)
                this.avg_velocity_mod(c) = mean(vecnorm([drv.particles.veloc_trl]));
            end
            if (this.has_avg_velocity_rot)
                this.avg_velocity_rot(c) = mean(abs([drv.particles.veloc_rot]));
            end
        end
        
        %------------------------------------------------------------------
        function storeAvgAcceleration(this,drv)
            c = this.idx;
            if (this.has_avg_acceleration_mod)
                this.avg_acceleration_mod(c) = mean(vecnorm([drv.particles.accel_trl]));
            end
            if (this.has_avg_acceleration_rot)
                this.avg_acceleration_rot(c) = mean(abs([drv.particles.accel_rot]));
            end
        end
        
        %------------------------------------------------------------------
        function storeAvgTemperature(this,drv)
            c = this.idx;
            if (this.has_avg_temperature)
                this.avg_temperature(c) = mean([drv.particles.temperature]);
            end
        end
        
        %------------------------------------------------------------------
        function storeExtVelocity(this,drv)
            c = this.idx;
            if (this.has_min_velocity_mod || this.has_max_velocity_mod)
                vt = vecnorm([drv.particles.veloc_trl]);
                if (this.has_min_velocity_mod)
                    this.min_velocity_mod(c) = min(vt);
                end
                if (this.has_max_velocity_mod)
                    this.max_velocity_mod(c) = max(vt);
                end
            end
            if (this.has_min_velocity_rot || this.has_max_velocity_rot)
                vr = [drv.particles.veloc_rot];
                if (this.has_min_velocity_rot)
                    this.min_velocity_rot(c) = min(vr);
                end
                if (this.has_max_velocity_rot)
                    this.max_velocity_rot(c) = max(vr);
                end
            end
        end
        
        %------------------------------------------------------------------
        function storeExtAcceleration(this,drv)
            c = this.idx;
            if (this.has_min_acceleration_mod || this.has_max_acceleration_mod)
                at = vecnorm([drv.particles.accel_trl]);
                if (this.has_min_acceleration_mod)
                    this.min_acceleration_mod(c) = min(at);
                end
                if (this.has_max_acceleration_mod)
                    this.max_acceleration_mod(c) = max(at);
                end
            end
            if (this.has_min_acceleration_rot || this.has_max_acceleration_rot)
                ar = [drv.particles.accel_rot];
                if (this.has_min_acceleration_rot)
                    this.min_acceleration_rot(c) = min(ar);
                end
                if (this.has_max_acceleration_rot)
                    this.max_acceleration_rot(c) = max(ar);
                end
            end
        end
        
        %------------------------------------------------------------------
        function storeExtTemperature(this,drv)
            c = this.idx;
            if (this.has_min_temperature)
                this.min_temperature(c) = min([drv.particles.temperature]);
            end
            if (this.has_max_temperature)
                this.max_temperature(c) = max([drv.particles.temperature]);
            end
        end
        
        %------------------------------------------------------------------
        function storeTotalHeatRate(this,drv)
            c = this.idx;
            if (this.has_tot_heat_rate_all || this.has_tot_conduction_direct || this.has_tot_conduction_indirect)
                cd = [drv.interacts.dconduc];
                ci = [drv.interacts.iconduc];
                if (isempty(cd) && isempty(ci))
                    heat_cd = 0;
                    heat_ci = 0;
                else
                    if (isempty(cd))
                        heat_cd = zeros(size([ci.total_hrate]));
                    else
                        heat_cd = [cd.total_hrate];
                    end
                    if (isempty(ci))
                        heat_ci = zeros(size([cd.total_hrate]));
                    else
                        heat_ci = [ci.total_hrate];
                    end
                end
                if (this.has_tot_heat_rate_all)
                    this.tot_heat_rate_all(c) = sum(abs(heat_cd+heat_ci));
                end
                if (this.has_tot_conduction_direct)
                    this.tot_conduction_direct(c) = sum(abs(heat_cd));
                end
                if (this.has_tot_conduction_indirect)
                    this.tot_conduction_indirect(c) = sum(abs(heat_ci));
                end
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
            if (this.has_wall_temperature && ~w.insulated)
                this.wall_temperature(r,c) = w.temperature;
            end
        end
    end
end