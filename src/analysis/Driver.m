%% Driver class
%
%% Description
%
% This is a handle super-class for the definition of an analysis driver.
%
% An analysis driver is the core of the simulation, being responsible to
% perform the time steps of particular types of analysis.
%
% It also does the pre and pos processing in public methods, since these
% tasks are common to all types of analysis.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <driver_mechanical.html Driver_Mechanical>
% * <driver_thermal.html Driver_Thermal>
% * <driver_thermomechanical.html Driver_ThermoMechanical>
%
classdef Driver < handle
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of analysis
        MECHANICAL        = uint8(1);
        THERMAL           = uint8(2);
        THERMO_MECHANICAL = uint8(3);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Problem data
        name string = string.empty;   % problem name
        type uint8  = uint8.empty;    % flag for type of analysis
        
        % Model components: total numbers
        n_mparts    uint32 = uint32.empty;   % number of model parts
        n_particles uint32 = uint32.empty;   % number of particles
        n_walls     uint32 = uint32.empty;   % number of walls
        n_interacts uint32 = uint32.empty;   % number of binary interactions
        n_materials uint32 = uint32.empty;   % number of materials
        
        % Model components: handle to objects
        mparts    ModelPart = ModelPart.empty;   % handles to objects of ModelPart class
        particles Particle  = Particle.empty;    % handles to objects of Particle class
        walls     Wall      = Wall.empty;        % handles to objects of Wall class
        interacts Interact  = Interact.empty;    % handles to objects of Interact class
        materials Material  = Material.empty;    % handles to objects of Material class
        
        % Model limits
        bbox BBox = BBox.empty;   % handle to object of BBox class
        sink Sink = Sink.empty;   % handles to objects of Sink class
        
        % Paralelization
        parallel logical = logical.empty;   % flag for parallelization of simulation
        workers  uint16  = uint16.empty;    % number of workers for parallelization
        
        % Neighbours search
        search Search = Search.empty;   % handle to object of Search class
        
        % Time advancing
        auto_step logical = logical.empty;   % flag for computing time step automatically
        time_step double  = double.empty;    % time step value
        max_time  double  = double.empty;    % maximum simulation time
        max_step  uint32  = uint32.empty;    % maximum step value allowed
        time      double  = double.empty;    % current simulation time
        step      uint32  = uint32.empty;    % current simulation step
        
        % Output generation
        result   Result  = Result.empty;    % handle to object of Result class
        graphs   Graph   = Graph.empty;     % handles to objects of Graph class
        animates Animate = Animate.empty;   % handles to objects of Animate class
        
        % Output control
        nprog double  = double.empty;    % progress print frequency (% of total time)
        nout  double  = double.empty;    % number of outputs
        tprog double  = double.empty;    % next time for printing progress
        tout  double  = double.empty;    % next time for storing results
        store logical = logical.empty;   % flag for step to store results
    end
    
    %% Constructor method
    methods
        function this = Driver(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        setParticleProps(this,particle);
        
        %------------------------------------------------------------------
        process(this);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function status = preProcess(this)
            status = 1;
            
            % Initialize time and step
            this.time = 0;
            this.step = 0;
            
            % loop over all particles
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Remove particles not respecting bbox and sinks
                if (this.removeParticle(p))
                    continue;
                end
                
                % Set basic properties
                this.setParticleProps(p);
                
                % Initialize forcing terms
                p.resetForcingTerms();
                
                % Set fixed temperature (fixed motion not set now)
                p.setFixedThermal(this.time);
                p.setFCTemperature(this.time);
            end
            
            % Erase handles to removed particles from global list and model parts
            this.eraseHandlesToRemovedParticle();
            if (this.n_particles == 0)
                fprintf(2,'The model has no particle inside the domain.\n');
                status = 0;
                return;
            end
            
            % loop over all walls
            for i = 1:this.n_walls
                w = this.walls(i);
                
                % Set fixed temperature (fixed motion not set now)
                w.setFixedThermal(this.time);
                w.setFCTemperature(this.time);
            end
            
            % Initialize critical time step
            if (this.auto_step)
                this.time_step = inf;
            end
            
            % Initialize result arrays
            this.result.initialize(this);
            
            % Add initial global values to result arrays
            this.result.storeGlobalParams(this);
            
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Compute critical time step for current particle
                if (this.auto_step)
                    dt = this.criticalTimeStep(p);
                    if (dt < this.time_step)
                        this.time_step = dt;
                    end
                end
                
                % Add initial particle values to result arrays
                this.result.storeParticleProp(p);
                this.result.storeParticleMotion(p);
                this.result.storeParticlePosition(p);
                this.result.storeParticleForce(p);
                this.result.storeParticleThermal(p);
            end
            
            % Compute ending time
            if (isempty(this.max_time))
                this.max_time = this.max_step * this.time_step;
            elseif (~isempty(this.max_step))
                this.max_time = min(this.max_time,this.max_step*this.time_step);
            end
                    
            % Add initial wall values to result arrays
            for i = 1:this.n_walls
                w = this.walls(i);
                this.result.storeWallPosition(w);
                this.result.storeWallThermal(w);
            end
            
            % Initialize output control variables
            this.nprog = this.nprog * this.max_time / 100;
            this.nout  = this.max_time / this.nout;
            this.tprog = this.nprog;
            this.tout  = this.nout;
        end
        
        %------------------------------------------------------------------
        function do = removeParticle(this,p)
            do = false;
            
            % Remove particles not respecting bbox
            if (~isempty(this.bbox))
                if (this.bbox.removeParticle(p,this.time))
                    do = true;
                    
                    % Remove particle and its interactions
                    delete(p.interacts);
                    delete(p);
                    
                    % Erase handles from global list of interactions
                    this.interacts(~isvalid(this.interacts)) = [];
                    this.n_interacts = length(this.interacts);
                    return;
                end
            end
            
            % Remove particles not respecting sinks
            if (~isempty(this.sink))
                for i = 1:length(this.sink)
                    if (this.sink(i).removeParticle(p,this.time))
                        do = true;
                        
                        % Remove particle and its interactions
                        delete(p.interacts);
                        delete(p);
                        
                        % Erase handles from global list of interactions
                        this.interacts(~isvalid(this.interacts)) = [];
                        this.n_interacts = length(this.interacts);
                        return;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function eraseHandlesToRemovedParticle(this)
            % Erase handles from global list
            this.particles(~isvalid(this.particles)) = [];
            this.n_particles = length(this.particles);
            
            % Erase handles from model parts
            for i = 1:this.n_mparts
                mp = this.mparts(i);
                mp.particles(~isvalid(mp.particles)) = [];
                mp.n_particles = length(mp.particles);
            end
        end
        
        %------------------------------------------------------------------
        function printProgress(this)
            if (this.time >= this.tprog)
                fprintf('\n%.1f%%: time %.2f, step %d',100*this.tprog/this.max_time,this.time,this.step);
                this.tprog = this.tprog + this.nprog;
            end
        end
        
        %------------------------------------------------------------------
        function do = storeResults(this)
            if (this.time >= this.tout)
                do = true;
                this.tout = this.tout + this.nout;
                this.result.updateIndex();
            else
                do = false;
            end
        end
        
        %------------------------------------------------------------------
        function posProcess(this)
            % Create graphs
            if (~isempty(this.graphs))
                fprintf('\nCreating graphs...\n');
                for i = 1:length(this.graphs)
                    this.graphs(i).execute(this);
                end
            end
            
            % Create and show animations
            if (~isempty(this.animates))
                for i = 1:length(this.animates)
                    fprintf('\nCreating animation %s...',this.animates(i).atitle);
                    this.animates(i).execute(this);
                end
                fprintf('\n');
                for i = 1:length(this.animates)
                    fprintf('\nShowing animation %s...\n',this.animates(i).atitle);
                    this.animates(i).show();
                end
            end
        end
    end
end