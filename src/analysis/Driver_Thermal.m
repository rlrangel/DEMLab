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
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.n_mparts    = 0;
            this.n_particles = 0;
            this.n_walls     = 0;
            this.n_interacts = 0;
            this.n_materials = 0;
            this.auto_step   = false;
            this.search      = Search_SimpleLoop();
            this.scheme_temp = Scheme_EulerForward();
            this.parallel    = false;
            this.workers     = parcluster('local').NumWorkers;
            this.result      = Result();
            this.save_ws     = true;
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
        function dt = criticalTimeStep(~,p)
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
        function process(this)
            % Interactions search (only once as particles do not move)
            this.search.execute(this);
            
            % Prepare interactions (never change during analysis)
            rmv = false;
            for i = 1:this.n_interacts
                int = this.interacts(i);
                
                % Remove insulated interactions
                if (int.insulated)
                    p = int.elem1;
                    w = int.elem2;
                    p.interacts(p.interacts==int) = [];
                    p.neigh_w(p.neigh_w==w.id)    = [];
                    delete(int);
                    rmv = true;
                    continue;
                end
                
                % Set constant parameters
                int.kinemat.is_contact    = true;
                int.kinemat.v0_n          = 0;
                int.kinemat.contact_start = 0;
                int.kinemat.contact_time  = inf;
                int.kinemat.dir_n         = int.kinemat.dir / int.kinemat.dist;
                int.kinemat.ovlp_n        = -int.kinemat.separ;
                int.kinemat = int.kinemat.setContactArea(int);
                int.setFixParamsTherm();
                int.setCteParamsTherm();
            end
            
            % Erase handles to removed interactions from global list
            if (rmv)
                this.interacts(~isvalid(this.interacts)) = [];
                this.n_interacts = length(this.interacts);
            end
            
            % Store fixed particle and wall positions to result arrays
            for i = 1:this.n_particles
                this.result.storeParticlePositionAll(this.particles(i));
            end
            for i = 1:this.n_walls
                this.result.storeWallPositionAll(this.walls(i));
            end
            
            % Time advancing
            while (this.time <= this.max_time)
                % Store current time and step to result arrays
                this.storeResults()
                if (this.store)
                    this.result.storeTime(this);
                end
                
                % Loop over all interactions, particles and walls
                this.interactionLoop();
                this.particleLoop();
                this.wallLoop();
                
                % Print progress
                this.printProgress();
                
                % Update time and step
                this.time = this.time + this.time_step;
                this.step = this.step + 1;
            end
            this.printProgress(); % last step (100%)
        end
    end
    
   %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function interactionLoop(this)
            for i = 1:this.n_interacts
                this.interacts(i).evalResultsTherm();
            end
        end
        
        %------------------------------------------------------------------
        function particleLoop(this)
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Set flag for fixed temperature
                p.setFixedThermal(this.time);
                
                % Solve thermal state
                if (p.free_therm)
                    % Add prescribed conditions
                    p.addPCHeatFlux(this.time);
                    p.addPCHeatRate(this.time);
                    
                    % Evaluate equation of energy balance (update temp. rate of change)
                    p.setTempChange();
                    
                    % Numerical integration (update temperature)
                    this.scheme_temp.updateTemperature(p,this.time_step);
                else
                    % Set fixed temperature
                    p.setFCTemperature(this.time);
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