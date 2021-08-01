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
            this.dimension   = 2;
            this.n_mparts    = 0;
            this.n_particles = 0;
            this.n_walls     = 0;
            this.n_interacts = 0;
            this.n_materials = 0;
            this.search      = Search_SimpleLoop();
            this.scheme_temp = Scheme_EulerForward();
            this.parallel    = any(any(contains(struct2cell(ver),'Parallel Computing Toolbox')));
            this.workers     = parcluster('local').NumWorkers;
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
                
                % Store current time and step to result arrays
                if (this.storeResults())
                    this.store = true;
                    this.result.storeGlobalParams(this);
                else
                    this.store = false;
                end
                
                % Loop over all interactions, particles and walls
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
            for i = 1:this.n_interacts
                int = this.interacts(i);
                
                % Evaluate contact interactions
                if (int.kinemat.separ < 0)
                    % Constant parameters needed to be set only once
                    if (this.step == 1)
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
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Set flag for free particle
                p.setFreeTherm(this.time);
                
                % Solve thermal state
                if (p.free_therm)
                    % Add prescribed conditions
                    p.addPCHeatFlux(this.time);
                    p.addPCHeatRate(this.time);
                    
                    % Evaluate equation of energy balance
                    p.setTempChange();
                    
                    % Numerical integration
                    this.scheme_temp.updateTemperature(p,this.time_step);
                else
                    % Set fixed temperature
                    p.setFCTemperature(this.time);
                end
                
                % Store results
                if (this.store)
                    this.result.storeParticlePosition(p);
                    this.result.storeParticleThermal(p);
                end
                
                % Reset forcing terms for next step
                p.resetForcingTerms();
            end
        end
        
        %------------------------------------------------------------------
        function wallLoop(this)
            for i = 1:this.n_walls
                w = this.walls(i);
                
                % Set fixed temperature
                w.setFreeTherm(his.time);
                w.setFCTemperature(his.time);
                
                % Store results
                if (this.store)
                    this.result.storeWallPosition(w);
                    this.result.storeWallThermal(w);
                end
            end
        end
    end
end