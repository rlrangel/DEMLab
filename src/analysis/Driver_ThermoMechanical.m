%% Driver_ThermoMechanical class
%
%% Description
%
% This is a sub-class of the <driver.html Driver> class for the
% implementation of the *Thermomechanical* analysis driver.
%
% In this type of analysis, the mechanical and thermal behaviors of
% particles are simulated.
%
% This class is responsible for solving all the time steps of a
% thermomechanical simulation by performing loops over all interactions,
% particles and walls in order to compute the changes of motion and thermal
% state.
%
classdef Driver_ThermoMechanical < Driver
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Forces / torques evaluation
        eval_freq uint32  = uint32.empty;    % evaluation frequency (in steps)
        eval      logical = logical.empty;   % flag for evaluating forces in current step
    end
    
    %% Constructor method
    methods
        function this = Driver_ThermoMechanical()
            this = this@Driver(Driver.THERMO_MECHANICAL);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            % Scalars
            this.n_mparts    = 0;
            this.n_particles = 0;
            this.n_walls     = 0;
            this.n_interacts = 0;
            this.n_solids    = 0;
            this.fluid_temp  = 0;
            this.alpha       = inf; % convex hull
            this.por_freq    = NaN; % never compute
            this.vor_freq    = NaN; % never compute
            this.eval_freq   = 1;   % always compute
            this.workers     = parcluster('local').NumWorkers; % max. available
            this.nprog       = 1;
            this.nout        = 100;
            % Vectors
            this.fluid_vel   = [0;0];
            % Booleans
            this.has_bbox    = false;
            this.has_sink    = false;
            this.auto_step   = false;
            this.eval        = true;  % according to eval_freq
            this.parallel    = false; % according to workers
            this.save_ws     = true;  % according to nout
            % Objects
            this.search      = Search_SimpleLoop();
            this.scheme_trl  = Scheme_EulerForward();
            this.scheme_rot  = Scheme_EulerForward();
            this.scheme_temp = Scheme_EulerForward();
            this.result      = Result();
        end
        
        %------------------------------------------------------------------
        function setParticleProps(this,p)
            p.setCharLen();
            p.setSurface();
            p.setCrossSec();
            p.setVolume();
            p.setMass();
            p.setMInertia();
            p.setTInertia();
            if (~isempty(this.gravity))
                p.setWeight(this.gravity);
            end
        end
        
        %------------------------------------------------------------------
        function dt = criticalTimeStep(~,p)
            % Mechanical critical time step
            % Refs.:
            % Li et al. A comparison of discrete element simulations and experiments for sandpiles composed of spherical particles, 2005
            dt_mech = pi * p.radius * sqrt(p.material.density / p.material.shear) / (0.8766 + 0.163 * p.material.poisson);
            
            % Apply reduction coefficient
            dt_mech = dt_mech * 0.01;
            
            % Thermal critical time step
            % Refs.:
            % Rojek, Discrete element thermomechanical modelling of rock cutting with valuation of tool wear, 2014
            dt_therm = p.radius * p.material.density * p.material.hcapacity / p.material.conduct;
            
            % Apply reduction coefficient
            dt_therm = dt_therm * 0.1;
            
            % Critical case
            dt = min(dt_mech,dt_therm);
            
            % Limit time step
            if (dt > 0.001)
                dt = 0.001;
            end
        end
        
        %------------------------------------------------------------------
        function status = preProcess(this)
            status = 1;
            this.initTime();
            
            % Initialize result arrays and add initial time and step values
            % (initialze arrays with NaN for all initial particles)
            this.result.initialize(this);
            this.result.storeTime(this);
            
            % loop over all particles
            erase = false;
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Remove particles not respecting bbox and sinks
                if (this.removeParticle(p))
                    erase = true;
                    continue;
                end
                
                % Initialize properties and forcing terms
                this.setParticleProps(p);
                p.resetForcingTerms();
                
                % Set fixed conditions (overlap initial conditions):
                % Only fixed temperature is set because fixed motion
                % also updates the particle kinematics (coordinates, etc).
                p.setFixedThermal(this.time);
                p.setFCTemperature(this.time);
                
                % Add initial particle values to result arrays:
                % Some results are not available yet and are zero, such as
                % forcing terms, but will receive a copy of the next step
                % (work-around).
                this.result.storeParticleProp(p);          % fixed all steps
                this.result.storeParticlePosition(p);      % initial
                this.result.storeParticleTemperature(p);   % initial
                this.result.storeParticleForce(p);         % zero (reset after 1st step)
                this.result.storeParticleVelocity(p);      % zero (reset after 1st step)
                this.result.storeParticleAcceleration(p);  % zero (reset after 1st step)
                this.result.storeParticleHeatRate(p);      % zero (reset after 1st step)
                
                % Compute critical time step for current particle
                if (this.auto_step)
                    dt = this.criticalTimeStep(p);
                    if (i == 1 || dt < this.time_step)
                        this.time_step = dt;
                    end
                end
            end
            
            % Update global properties depending on total number of particles 
            if (erase)
                this.erasePropsOfRemovedParticle();
            end
            if (this.n_particles == 0)
                fprintf(2,'The model has no particle inside the domain to initialize the analysis.\n');
                status = 0;
                return;
            end
            
            % Set global properties
            % Assumption: particles porosity depends on interaction search,
            % so it is initially set as the global porosity.
            this.setTotalParticlesProps();
            this.setGlobalVol();
            if (isempty(this.porosity))
                this.setGlobalPorosity();
            end
            for i = 1:this.n_particles
                this.particles(i).setLocalPorosity(this.porosity);
            end
            
            % Loop over all walls
            for i = 1:this.n_walls
                w = this.walls(i);
                
                % Set fixed conditions (overlap initial conditions):
                % Only fixed temperature is set because fixed motion
                % also updates the wall kinematics (coordinates, etc).
                w.setFixedThermal(this.time);
                w.setFCTemperature(this.time);
                
                % Add initial wall values to result arrays
                this.result.storeWallPosition(w);      % initial
                this.result.storeWallTemperature(w);   % initial
            end
            
            % Print initial configuration
            if (~isempty(this.print))
                this.print.execute(this);
            end
            
            % Initialize search algorithm
            this.search.initialize(this);
            
            % Initialize output control variables
            this.initOutputVars();
        end
        
        %------------------------------------------------------------------
        function process(this)
            while (this.time <= this.max_time)
                % Check if it is time to store results:
                % Time & step not stored after 1st step as it was already stored in preprocess.
                % Global results stored after 1st step as some results were not ready before.
                this.storeResults()
                if (this.store || this.step == 1)
                    if (this.store)
                        this.result.storeTime(this);
                    end
                    this.result.storeAvgVelocity(this);
                    this.result.storeExtVelocity(this);
                    this.result.storeAvgAcceleration(this);
                    this.result.storeExtAcceleration(this);
                    this.result.storeAvgTemperature(this);
                    this.result.storeExtTemperature(this);
                    this.result.storeTotalHeatRate(this);
                end
                
                % Interactions search
                if (mod(this.step,this.search.freq) == 0)
                    this.search.execute(this);
                end
                
                % Update global volume/porosity
                if (mod(this.step,this.por_freq) == 0)
                    this.setGlobalVol();
                    this.setGlobalPorosity();
                end
                
                % Update voronoi diagram
                if (mod(this.step,this.vor_freq) == 0)
                    this.setVoronoiDiagram();
                end
                
                % Loop over all interactions
                if (this.eval)
                    this.interactionLoop();
                end
                
                % Loop over all particles and walls
                this.particleLoop();
                this.wallLoop();
                
                % Print progress
                this.printProgress();
                
                % Update variables for next step
                this.time = this.time + this.time_step;
                this.step = this.step + 1;
                this.search.done = false;
            end
            
            % Ensure that last step was saved
            this.printProgress();
            this.storeResultsFinal();
        end
    end
        
   %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function interactionLoop(this)
            for i = 1:this.n_interacts
                int = this.interacts(i);
                
                % Update relative position (if not already done in search)
                if (~this.search.done)
                    int.kinemat = int.kinemat.setRelPos(int.elem1,int.elem2);
                end
                
                % Update voronoi edges
                if (mod(this.step,this.vor_freq) == 0)
                    int.kinemat = int.kinemat.setVoronoiEdge(this,int);
                end
                
                % Evaluate contact interactions
                if (int.kinemat.separ < 0)
                    % Update overlap parameters and contact area
                    int.kinemat = int.kinemat.setOverlaps(int,this.time_step);
                    int.kinemat = int.kinemat.setContactArea(int);
                    
                    % Set initial and constant contact parameters
                    if (isempty(int.kinemat.is_contact) || ~int.kinemat.is_contact)
                        int.kinemat = int.kinemat.setInitContactParams(this.time);
                        int.setCteParamsMech();
                        int.setCteParamsTherm(this);
                    end
                    
                    % Update contact duration
                    int.kinemat.contact_time = this.time - int.kinemat.contact_start;
                    
                    % Compute and add interaction results to particles
                    int.evalResultsMech();
                    int.evalResultsTherm(this);
                    
                % Evaluate noncontact interactions
                % (currently, only thermal interactions can be non-contact)
                else
                    % Set initial and constant noncontact parameters
                    if (isempty(int.kinemat.is_contact) || int.kinemat.is_contact)
                        int.kinemat = int.kinemat.setInitNoncontactParams();
                        int.setCteParamsTherm(this);
                    end
                    
                    % Compute and add interaction results to particles
                    int.evalResultsTherm(this);
                end
            end
        end
        
        %------------------------------------------------------------------
        function particleLoop(this)
            % Initialize flags
            rmv = false;
            
            % Loop over all particles
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Set flags for fixed behaviors
                p.setFixedMech(this.time);
                p.setFixedThermal(this.time);
                
                % Solve translational motion
                if (p.free_trl)
                    % Evaluate particle forces
                    if (this.eval)
                        % Add global conditions
                        p.addWeight();
                        if (~isempty(this.damp_trl))
                            p.addGblDampTransl(this.damp_trl);
                        end

                        % Add prescribed conditions
                        p.addPCForce(this.time);
                    end
                    
                    % Evaluate equation of motion (update acceleration)
                    p.setAccelTrl();
                    
                    % Numerical integration (update vel, coord)
                    this.scheme_trl.updatePosition(p,this.time_step);
                else
                    % Set fixed translation (update accel, vel, coord)
                    p.setFCTranslation(this.time,this.time_step);
                end
                
                % Remove particles not respecting bbox and sinks
                if (this.removeParticle(p))
                    rmv = true;
                    continue;
                end
                
                % Solve rotational motion
                if (p.free_rot)
                    % Evaluate particle torques
                    if (this.eval)
                        % Add global conditions
                        if (~isempty(this.damp_rot))
                            p.addGblDampRot(this.damp_rot);
                        end
                        
                        % Add prescribed conditions
                        p.addPCTorque(this.time);
                    end
                    
                    % Evaluate equation of motion (update acceleration)
                    p.setAccelRot();
                    
                    % Numerical integration (update vel, orientation)
                    this.scheme_rot.updateOrientation(p,this.time_step);
                else
                    % Set fixed rotation (update accel, vel, orientation)
                    p.setFCRotation(this.time,this.time_step);
                end
                
                % Solve thermal state
                if (p.free_therm)
                    % Add prescribed conditions
                    p.addPCHeatFlux(this.time);
                    p.addPCHeatRate(this.time);
                    
                    % Add convection heat transfer from surrounding fluid
                    p.setConvCoeff(this);
                    p.addConvection(this);
                    
                    % Evaluate equation of energy balance (update temp. rate of change)
                    p.setTempChange();
                    
                    % Numerical integration (update temperature)
                    this.scheme_temp.updateTemperature(p,this.time_step);
                else
                    % Set fixed temperature
                    p.setFCTemperature(this.time);
                end
                
                % Update local porosity
                if (mod(this.step,p.por_freq) == 0)
                    p.setLocalPorosity([]);
                end
                
                % Store results
                if (this.step == 0)
                    % Work-around to fill null initial values stored in pre-process
                    this.result.storeParticleForce(p);
                    this.result.storeParticleVelocity(p);
                    this.result.storeParticleAcceleration(p);
                    this.result.storeParticleHeatRate(p);
                elseif (this.store)
                    this.result.storeParticlePosition(p);
                    this.result.storeParticleForce(p);
                    this.result.storeParticleVelocity(p);
                    this.result.storeParticleAcceleration(p);
                    this.result.storeParticleTemperature(p);
                    this.result.storeParticleHeatRate(p);
                end
                
                % Reset forcing terms for next step
                if (this.eval_freq == 1)
                    p.resetForcingTerms();
                elseif (mod(this.step+1,this.eval_freq) == 0)
                    p.resetForcingTerms();
                    this.eval = true;
                else
                    this.eval = false;
                end
            end
            
            % Erase handles to removed particles from global list and model parts
            if (rmv)
                this.erasePropsOfRemovedParticle;
            end
        end
        
        %------------------------------------------------------------------
        function wallLoop(this)            
            for i = 1:this.n_walls
                w = this.walls(i);
                
                % Set fixed motion
                w.setFixedMotion(this.time);
                w.setFCMotion(this.time,this.time_step);
                
                % Set fixed temperature
                w.setFixedThermal(this.time);
                w.setFCTemperature(this.time);
                
                % Store results
                if (this.store)
                    this.result.storeWallPosition(w);
                    this.result.storeWallTemperature(w);
                end
            end
        end
    end
end