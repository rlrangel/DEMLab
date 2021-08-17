%% Driver class
%
%% Description
%
% This is a handle super-class for the definition of an analysis driver.
%
% An analysis driver is the core of the simulation, being responsible to
% perform the time steps of the different types of analysis,
% and also the pre and pos processing tasks.
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
        path string = string.empty;   % path to model folder
        
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
        
        % Elapsed time control (real analysis time)
        start_time double  = double.empty;   % starting elapsed time for current analysis run
        total_time double  = double.empty;   % total elapsed time for all analysis runs
        
        % Output generation
        result     Result    = Result.empty;      % handle to object of Result class
        graphs     Graph     = Graph.empty;       % handles to objects of Graph class
        animations Animation = Animation.empty;   % handles to objects of Animation class
        save_ws    logical   = logical.empty;     % flag for saving workspace into a results file
        
        % Output control
        nprog double  = double.empty;    % progress print frequency (% of total time)
        tprog double  = double.empty;    % next time for printing progress
        nout  double  = double.empty;    % number of outputs
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
        preProcess(this);
        
        %------------------------------------------------------------------
        process(this);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function initTime(this)
            this.start_time = 0;
            this.time       = 0;
            this.step       = 0;
        end
        
        %------------------------------------------------------------------
        function finalTime(this)
            if (isempty(this.max_time))
                this.max_time = this.max_step * this.time_step;
            elseif (~isempty(this.max_step))
                this.max_time = min(this.max_time,this.max_step*this.time_step);
            end
        end
        
        %------------------------------------------------------------------
        function initOutputVars(this)
            this.nprog = this.nprog * this.max_time / 100; % convert to time per print
            this.nout  = this.max_time / this.nout;        % convert to time per output
            this.tprog = this.nprog;
            this.tout  = this.nout;
        end
        
        %------------------------------------------------------------------
        % Object must be called 'drv' here to load it from results file.
        function storeResults(drv)
            if (drv.time >= drv.tout)
                if (drv.save_ws)
                    save(strcat(drv.path,'\',drv.name));
                    drv.total_time = drv.start_time + toc;
                end
                drv.tout = drv.tout + drv.nout - 10e-10; % tollerance to deal with precision issues
                drv.result.updateIndex();
                drv.store = true;
            else
                drv.store = false;
            end
        end
        
        %------------------------------------------------------------------
        function printProgress(this)
            if (this.time >= this.tprog)
                fprintf('\n%.1f%%: time %.3f, step %d',100*this.tprog/this.max_time,this.time,this.step);
                this.tprog = this.tprog + this.nprog - 10e-15; % tollerance to deal with precision issues
            end
        end
        
        %------------------------------------------------------------------
        function cleanParticles(this)
            for i = 1:this.n_particles
                this.removeParticle(this.particles(i))
            end
            this.eraseHandlesToRemovedParticle();
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
        function posProcess(this)
            if (isnan(this.result.times(1)))
                fprintf('\nNo valid results to show.\n');
                return;
            end
            
            % Create and write graphs
            if (~isempty(this.graphs))
                fprintf('\nCreating graphs...\n');
                for i = 1:length(this.graphs)
                    this.graphs(i).execute(this);
                end
            end
            
            % Create and show animations
            if (~isempty(this.animations))
                for i = 1:length(this.animations)
                    fprintf('\nCreating animation "%s"...',this.animations(i).anim_title);
                    this.animations(i).animate(this);
                end
                fprintf('\n');
                for i = 1:length(this.animations)
                    fprintf('\nShowing animation "%s"...\n',this.animations(i).anim_title);
                    this.animations(i).showAnimation();
                end
            end
        end
    end
end