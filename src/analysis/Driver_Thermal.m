%% Driver_Thermal class
%
%% Description
%
% This is a sub-class of the <driver.html Driver> class for the
% implementation of the *Thermal* analysis driver.
%
% In this type of analysis only the thermal behavior of particles is
% simulated (particles motion is not computed).
%
% This class is responsible for solving all the time steps of a thermal
% simulation by performing loops over all interactions, particles and walls
% in order to compute the changes of temperature.
%
classdef Driver_Thermal < Driver
    %% Constructor method
    methods
        function this = Driver_Thermal()
            this = this@Driver(Driver.THERMAL);
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
            this.workers     = parcluster('local').NumWorkers; % max. available
            this.nprog       = 1;
            this.nout        = 100;
            % Vectors
            this.fluid_vel   = [0;0];
            % Booleans
            this.has_bbox    = false;
            this.has_sink    = false;
            this.auto_step   = false;
            this.parallel    = false; % according to workers
            this.save_ws     = true;  % according to nout
            % Objects
            this.search      = Search_SimpleLoop();
            this.scheme_temp = Scheme_EulerForward();
            this.result      = Result();
        end
        
        %------------------------------------------------------------------
        function setParticleProps(~,p)
            p.setCharLen();
            p.setSurface();
            p.setCrossSec();
            p.setVolume();
            p.setMass();
            p.setTInertia();
        end
        
        %------------------------------------------------------------------
        function dt = criticalTimeStep(~,p)
            % Refs.:
            % Rojek, Discrete element thermomechanical modelling of rock cutting with valuation of tool wear, 2014
            dt = p.radius * p.material.density * p.material.hcapacity / p.material.conduct;
            
            % Apply reduction coefficient
            dt = dt * 0.1;
            
            % Limit time step
            if (dt > 0.01)
                dt = 0.01;
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
            
            % 1st loop over all particles
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
                
                % Set fixed temperature (overlap initial condition)
                p.setFixedThermal(this.time);
                p.setFCTemperature(this.time);
                
                % Add initial/fixed particle values to result arrays:
                % Some results are not available yet and are zero, such as
                % forcing terms, but will receive a copy of the next step
                % (work-around).
                this.result.storeParticleProp(p);          % fixed all steps
                this.result.storeParticlePositionAll(p);   % fixed all steps
                this.result.storeParticleTemperature(p);   % initial
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
            this.setTotalParticlesProps();
            this.setGlobalVol();
            if (isempty(this.porosity))
                this.setGlobalPorosity();
            end
            if (~isnan(this.vor_freq))
                this.setVoronoiDiagram();
            end
            
            % Loop over all walls
            for i = 1:this.n_walls
                w = this.walls(i);
                
                % Set fixed temperature (overlap initial condition)
                w.setFixedThermal(this.time);
                w.setFCTemperature(this.time);
                
                % Add initial/fixed wall values to result arrays
                this.result.storeWallPositionAll(w);   % fixed all steps
                this.result.storeWallTemperature(w);   % initial
            end
            
            % Initialize output control variables
            this.initOutputVars();
            
            % Interactions search (only once as particles do not move)
            fprintf('\nCreating particle interactions...\n');
            this.search.execute(this);
            
            % 2nd loop over all particles (interaction-dependent properties)
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Set particles local porosity (needs particles interactions ready)
                p.setLocalPorosity([]);
                
                % Set particles convection coefficient (may need porosity ready)
                p.setConvCoeff(this);
            end
            
            % Prepare interactions for analysis
            for i = 1:this.n_interacts
                int = this.interacts(i);
                
                % Remove insulated interactions with walls
                if (int.insulated)
                    p = int.elem1; w = int.elem2;
                    p.interacts(p.interacts==int)  = [];
                    p.neigh_w(p.neigh_w==w)        = [];
                    p.neigh_wid(p.neigh_wid==w.id) = [];
                    delete(int);
                    continue;
                end
                
                % Set contact or non-contact parameters
                if (int.kinemat.separ < 0)
                    int.kinemat.contact_time = inf;
                    int.kinemat = int.kinemat.setOverlaps(int,this.time_step);
                    int.kinemat = int.kinemat.setContactArea(int);
                    int.kinemat = int.kinemat.setInitContactParams(this.time);
                else
                    int.kinemat.contact_time = 0;
                    int.kinemat = int.kinemat.setInitNoncontactParams();
                end
                if (~isnan(this.vor_freq))
                    int.kinemat = int.kinemat.setVoronoiEdge(this,int);
                end
                int.setFixParamsTherm(this);
                int.setCteParamsTherm(this);
            end
            
            % Erase handles to removed interactions from global list
            this.interacts(~isvalid(this.interacts)) = [];
            this.n_interacts = length(this.interacts);
        end
        
        %------------------------------------------------------------------
        function process(this)
            while (this.time <= this.max_time)
                % Check if it is time to store results:
                % Time & step not stored after 1st step as it was alreadystored in preprocess.
                % Global results stored after 1st step as some results were not ready before.
                this.storeResults()
                if (this.store || this.step == 1)
                    if (this.store)
                        this.result.storeTime(this);
                    end
                    this.result.storeAvgTemperature(this);
                    this.result.storeExtTemperature(this);
                    this.result.storeTotalHeatRate(this);
                end
                
                % Loop over all interactions, particles and walls
                for i = 1:this.n_interacts
                    this.interacts(i).evalResultsTherm(this);
                end
                this.particleLoop();
                this.wallLoop();
                
                % Print progress
                this.printProgress();
                
                % Update time and step
                this.time = this.time + this.time_step;
                this.step = this.step + 1;
            end
            
            % Ensure that last step was saved
            this.printProgress();
            this.storeResultsFinal();
        end
    end
    
   %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function particleLoop(this)
            % Initialize flags
            rmv = false;
            
            % Loop over all particles
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Set flag for fixed temperature
                p.setFixedThermal(this.time);
                
                % Solve thermal state
                if (p.free_therm)
                    % Add prescribed conditions
                    p.addPCHeatFlux(this.time);
                    p.addPCHeatRate(this.time);
                    
                    % Add convection heat transfer from surrounding fluid
                    p.addConvection(this);
                    
                    % Evaluate equation of energy balance (update temp. rate of change)
                    p.setTempChange();
                    
                    % Numerical integration (update temperature)
                    this.scheme_temp.updateTemperature(p,this.time_step);
                else
                    % Set fixed temperature
                    p.setFCTemperature(this.time);
                end
                
                % Remove particles not respecting bbox and sinks
                if (this.removeParticle(p))
                    rmv = true;
                    continue;
                end
                
                % Store results
                if (this.step == 0)
                    % Work-around to fill null initial values stored in pre-process
                    this.result.storeParticleHeatRate(p);
                elseif (this.store)
                    this.result.storeParticleTemperature(p);
                    this.result.storeParticleHeatRate(p);
                end
                
                % Reset forcing terms for next step
                p.resetForcingTerms();
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
                
                % Set fixed temperature
                w.setFixedThermal(this.time);
                w.setFCTemperature(this.time);
                
                % Store results
                if (this.store)
                    this.result.storeWallTemperature(w);
                end
            end
        end
    end
end