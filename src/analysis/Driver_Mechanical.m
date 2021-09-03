%% Driver_Mechanical class
%
%% Description
%
% This is a sub-class of the <driver.html Driver> class for the
% implementation of the *Mechanical* analysis driver.
%
% In this type of analysis only the mechanical behavior of particles is
% simulated (kinetics and kinematics).
%
% This class is responsible for solving all the time steps of a mechanical
% simulation by performing loops over all interactions, particles and walls
% in order to compute the changes of motion.
%
classdef Driver_Mechanical < Driver
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Forces / torques evaluation
        eval_freq uint32  = uint32.empty;    % evaluation frequency (in steps)
        eval      logical = logical.empty;   % flag for evaluating forces in current step
    end
    
    %% Constructor method
    methods
        function this = Driver_Mechanical()
            this = this@Driver(Driver.MECHANICAL);
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
            this.auto_step   = false;
            this.eval        = true;  % according to eval_freq
            this.parallel    = false; % according to workers
            this.save_ws     = true;  % according to nout
            % Objects
            this.search      = Search_SimpleLoop();
            this.scheme_trl  = Scheme_EulerForward();
            this.scheme_rot  = Scheme_EulerForward();
            this.result      = Result();
        end
        
        %------------------------------------------------------------------
        function setParticleProps(this,p)
            p.setSurface();
            p.setCrossSec();
            p.setVolume();
            p.setMass();
            p.setMInertia();
            if (~isempty(this.gravity))
                p.setWeight(this.gravity);
            end
        end
        
        %------------------------------------------------------------------
        function dt = criticalTimeStep(~,p)
            % Refs.:
            % Li et al. A comparison of discrete element simulations and experiments for sandpiles composed of spherical particles, 2005
            dt = pi * p.radius * sqrt(p.material.density / p.material.shear) / (0.8766 + 0.163 * p.material.poisson);
            
            % Apply reduction coefficient
            dt = dt * 0.01;
            
            % Limit time step
            if (dt > 0.001)
                dt = 0.001;
            end
        end
        
        %------------------------------------------------------------------
        function status = preProcess(this)
            status = 1;
            this.initTime();
            
            % Remove particles not respecting bbox and sinks
            % (total number of particles needed for preallocating results)
            this.cleanParticles();
            if (this.n_particles == 0)
                fprintf(2,'The model has no particle inside the domain to initialize the analysis.\n');
                status = 0;
                return;
            end
            
            % Initialize result arrays and add initial time and step values
            this.result.initialize(this);
            this.result.storeTime(this);
            
            % loop over all particles
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Initialize properties and forcing terms
                this.setParticleProps(p);
                this.setLocalPorosity(p);
                p.resetForcingTerms();
                
                % Add initial particle values to result arrays:
                % Some results are not available yet and are zero, such as
                % forcing terms, but will receive a copy of the next step
                % (work-around).
                this.result.storeParticleProp(p);          % fixed all steps
                this.result.storeParticlePosition(p);      % initial
                this.result.storeParticleForce(p);         % zero (reset after 1st step)
                this.result.storeParticleVelocity(p);      % zero (reset after 1st step)
                this.result.storeParticleAcceleration(p);  % zero (reset after 1st step)
                
                % Compute critical time step for current particle
                if (this.auto_step)
                    dt = this.criticalTimeStep(p);
                    if (i == 1 || dt < this.time_step)
                        this.time_step = dt;
                    end
                end
            end
            
            % Set global properties
            this.setTotalParticlesProps();
            this.voronoiDiagram();
            this.setGlobalVol();
            if (isempty(this.porosity))
                this.setGlobalPorosity();
            end
            
            % Loop over all walls
            for i = 1:this.n_walls
                % Add initial wall values to result arrays
                w = this.walls(i);
                this.result.storeWallPosition(w);
            end
            
            % Compute ending time
            this.finalTime();
            
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
                if (this.store || step == 1)
                    if (this.store)
                        this.result.storeTime(this);
                    end
                    this.result.storeAvgVelocity(this);
                    this.result.storeExtVelocity(this);
                    this.result.storeAvgAcceleration(this);
                    this.result.storeExtAcceleration(this);
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
                    this.voronoiDiagram();
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
            % Evaluate interactions:
            % Only contact interactions available in mechanical analysis
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
                
                % Update overlap parameters and contact area
                int.kinemat = int.kinemat.setOverlaps(int,this.time_step);
                int.kinemat = int.kinemat.setContactArea(int);
                
                % Set initial and constant contact parameters
                if (isempty(int.kinemat.is_contact))
                    int.kinemat = int.kinemat.setInitContactParams(this.time);
                    int.setCteParamsMech();
                end
                
                % Compute and add interaction results to particles
                int.evalResultsMech();
            end
        end
        
        %------------------------------------------------------------------
        function particleLoop(this)
            % Initialize flags
            rmv = false;
            
            % Loop over all particles
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Set flags for fixed motion
                p.setFixedMech(this.time);
                
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
                
                % Update local porosity
                if (mod(this.step,p.por_freq) == 0)
                    this.setLocalPorosity(p);
                end
                
                % Store results
                if (this.step == 0)
                    % Work-around to fill null initial values stored in pre-process
                    this.result.storeParticleForce(p);
                    this.result.storeParticleVelocity(p);
                    this.result.storeParticleAcceleration(p);
                elseif (this.store)
                    this.result.storeParticlePosition(p);
                    this.result.storeParticleForce(p);
                    this.result.storeParticleVelocity(p);
                    this.result.storeParticleAcceleration(p);
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
                
                % Set fixed motion (also update vel, coord)
                w.setFixedMotion(this.time);
                w.setFCMotion(this.time,this.time_step);
                
                % Store results
                if (this.store)
                    this.result.storeWallPosition(w);
                end
            end
        end
    end
end