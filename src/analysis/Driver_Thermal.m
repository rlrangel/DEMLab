%% Driver_Thermal class
%
%% Description
%
%% Implementation
%
classdef Driver_Thermal < Driver
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Time integration
        scheme_temp Scheme = Scheme.empty;   % handle to object of Scheme class for temperature integration
    end
    
    %% Constructor method
    methods
        function this = Driver_Thermal()
            this = this@Driver(Driver.THERMAL);
            this.setDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.n_mparts    = 0;
            this.n_particles = 0;
            this.n_walls     = 0;
            this.n_interacts = 0;
            this.n_materials = 0;
            this.n_prescond  = 0;
            this.search      = Search_SimpleLoop();
            this.scheme_temp = Scheme_EulerForward();
            this.parallel    = any(any(contains(struct2cell(ver),'Parallel Computing Toolbox')));
            this.workers     = parcluster('local').NumWorkers;
            this.auto_step   = false;
            this.result      = Result();
            this.nprog       = 1;
            this.nout        = 500;
        end
        
        %------------------------------------------------------------------
        function setParticleProps(~,p)
            p.setSurface();
            p.setVolume();
            p.setMass();
            p.setTInertia();
        end
        
        %------------------------------------------------------------------
        function runAnalysis(this)
            while (this.time < this.max_time)
                % Update time and step
                this.time = this.time + this.time_step;
                this.step = this.step + 1;
                
                % Loop over all interactions and particles
                this.interactionLoop();
                this.particleLoop();
                this.wallLoop();
                
                % Print progress
                this.printProgress();
            end
        end
    end
    
   %% Public methods: Subclass specifics
    methods
        %------------------------------------------------------------------
        function interactionLoop(this)
            % Properties accessed in parallel loop
            interacts = this.interacts;
            step = this.step;
            
            % Loop over all interactions
            for i = 1:this.n_interacts
                int = interacts(i);
                
                % Evaluate contact interactions
                if (int.kinemat.separ < 0)
                    % Constant parameters needed to be set only once
                    if (step == 1)
                        int.kinemat.is_contact = true;
                        int.kinemat.dir_n  =  int.kinemat.dir / int.kinemat.dist;
                        int.kinemat.ovlp_n = -int.kinemat.separ;
                        int.kinemat = int.kinemat.setContactArea(int);
                        int.cconduc = int.cconduc.setParameters(int);
                    end
                    
                    % Compute interaction results and add to particles
                    int.cconduc = int.cconduc.evalHeatRate(int);
                    int.kinemat.addContactConductionToParticles(int);
                end
            end
        end
        
        %------------------------------------------------------------------
        function particleLoop(this)
            % Properties accessed in parallel loop
            particles = this.particles;
            time      = this.time;
            time_step = this.time_step;
            
            % Initialize flags
            store = this.storeResults();
            
            % Store current time and step to result arrays
            if (store)
                this.result.storeGlobalParams(this);
            end
            
            % Loop over all particles
            for i = 1:this.n_particles
                p = particles(i);
                
                % Solver thermal state
                if (isempty(p.fc_temperature))
                    % Add prescribed conditions
                    p.addPCHeatFlux(time);
                    p.addPCHeatRate(time);
                    
                    % Evaluate equation of energy balance
                    p.computeTempChange();
                    
                    % Numerical integration
                    this.scheme_temp.updateTemperature(p,time_step);
                else
                    % Set fixed conditions
                    p.setFCTemperature(time);
                end
                
                % Store results
                if (store)
                    this.result.storeParticlePosition(p);
                    this.result.storeParticleThermal(p);
                end
                
                % Reset forcing terms for next step
                p.resetForcingTerms();
            end
        end
        
        %------------------------------------------------------------------
        function wallLoop(this)
            % Properties accessed in parallel loop
            walls = this.walls;
            time  = this.time;
            
            % Loop over all walls
            for i = 1:this.n_walls
                w = walls(i);
                
                % Set fixed conditions
                w.setFCTemperature(time);
            end
        end
    end
end