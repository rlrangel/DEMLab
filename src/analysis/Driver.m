%% Driver class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Driver < handle
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of analysis
        MECHANICAL        = int8(1);
        THERMAL           = int8(2);
        THERMO_MECHANICAL = int8(3);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Problem data
        name      string = string.empty;   % problem name
        type      uint8  = uint8.empty;    % flag for type of analysis
        dimension uint8  = uint8.empty;    % model dimension
        
        % Model components: total numbers
        n_mparts    uint32 = uint32.empty;   % number of model parts
        n_particles uint32 = uint32.empty;   % number of particles
        n_walls     uint32 = uint32.empty;   % number of walls
        n_interacts uint32 = uint32.empty;   % number of binary interactions
        n_materials uint32 = uint32.empty;   % number of materials
        n_prescond  uint32 = uint32.empty;   % number of prescribed conditions
        
        % Model components: handle to objects
        mparts    ModelPart = ModelPart.empty;   % handles to objects of ModelPart class
        particles Particle  = Particle.empty;    % handles to objects of Particle class
        walls     Wall      = Wall.empty;        % handles to objects of Wall class
        interacts Interact  = Interact.empty;    % handles to objects of Interact class
        materials Material  = Material.empty;    % handles to objects of Material class
        prescond  PC        = PC.empty;          % handles to objects of PC class
        
        % Model limits
        bbox BBox = BBox.empty;   % handle to object of BBox class
        sink Sink = Sink.empty;   % handles to objects of Sink class
        
        % Paralelization
        parallel logical = logical.empty;   % flag for parallelization of simulation
        workers  uint16  = uint16.empty;    % number of workers for parallelization
        
        % Neighbours search
        search Search = Search.empty;   % handle to object of Search class
        
        % Time advancing
        auto_step logical = logical.empty;   % flag for automatic time step
        time_step double  = double.empty;    % time step value
        max_time  double  = double.empty;    % maximum simulation time
        max_step  uint32  = uint32.empty;    % maximum step value allowed
        time      double  = double.empty;    % current simulation time
        step      uint32  = uint32.empty;    % current simulation step
        
        % Output
        nprog double = double.empty;   % progress print frequency (% of total time)
        nout  double = double.empty;   % number of outputs
        tprog double = double.empty;   % next time for printing progress
        tout  double = double.empty;   % next time for storing results
    end
    
    %% Constructor method
    methods
        function this = Driver(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        setParticleProps(this,particle);
        
        %------------------------------------------------------------------
        runAnalysis(this);
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
            end
            
            % Erase handles to removed particles from global list and model parts
            this.eraseHandlesToRemovedParticle();
            if (this.n_particles == 0)
                fprintf(2,'The model has no particle.\n');
                status = 0;
                return;
            end
            
            % Interactions search
            this.search.execute(this);
            
            % Compute limit ending time
            if (isempty(this.max_time))
                this.max_time = this.max_step * this.time_step;
            elseif (~isempty(this.max_step))
                this.max_time = min(this.max_time,this.max_step*this.time_step);
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
                for j = 1:length(this.sink)
                    if (this.sink(j).removeParticle(p,this.time))
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
            else
                do = false;
            end
        end
    end
end