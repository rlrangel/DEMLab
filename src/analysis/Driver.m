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
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <Driver_Mechanical.html Driver_Mechanical>
% * <Driver_Thermal.html Driver_Thermal>
% * <Driver_ThermoMechanical.html Driver_ThermoMechanical>
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
        name    string = string.empty;   % simulation name
        type    uint8  = uint8.empty;    % flag for type of analysis
        path_in string = string.empty;   % path to input files folder
        
        % Model components: handle to objects
        mparts    ModelPart = ModelPart.empty;   % handles to objects of ModelPart class
        particles Particle  = Particle.empty;    % handles to objects of Particle class
        walls     Wall      = Wall.empty;        % handles to objects of Wall class
        interacts Interact  = Interact.empty;    % handles to objects of Interact class
        solids    Material  = Material.empty;    % handles to objects of Material_Solid subclass
        fluid     Material  = Material.empty;    % handles to object of Material_Fluid subclass
        
        % Model components: total numbers
        n_mparts    uint32 = uint32.empty;   % number of model parts
        n_particles uint32 = uint32.empty;   % number of particles
        n_walls     uint32 = uint32.empty;   % number of walls
        n_interacts uint32 = uint32.empty;   % number of binary interactions
        n_solids    uint32 = uint32.empty;   % number of solid materials
        
        % Global properties
        gravity    double = double.empty;   % vector of gravity components value
        damp_trl   double = double.empty;   % damping for translational motion
        damp_rot   double = double.empty;   % damping for rotational motion
        fluid_vel  double = double.empty;   % interstitial fluid velocity vector
        fluid_temp double = double.empty;   % interstitial fluid temperature
        
        % Model domain properties
        alpha      double = double.empty;   % alpha radius
        vol_domain double = double.empty;   % total volume (unity depth) of the alpha-shape polygon of all particles
        porosity   double = double.empty;   % average porosity (void ratio) of the alpha-shape polygon
        por_freq   double = double.empty;   % average porosity update frequency (in steps) (double to accept NaN)
        vor_freq   double = double.empty;   % voronoi diagram update frequency (in steps) (double to accept NaN)
        vor_vtx    double = double.empty;   % vertices coordinates of voronoi diagram
        vor_idx    cell   = cell.empty;     % vertices indices of voronoi diagram cells
        
        % Total particle properties
        surf_particle  double = double.empty;   % total surface area of all particles
        cross_particle double = double.empty;   % total cross-sectional area of all particles
        vol_particle   double = double.empty;   % total volume of all particles
        mass_particle  double = double.empty;   % total mass of all particles
        
        % Model limits
        has_bbox logical = logical.empty;   % flag for existing bbox
        has_sink logical = logical.empty;   % flag for existing sinks
        bbox     BBox    = BBox.empty;      % handle to object of BBox class
        sink     Sink    = Sink.empty;      % handles to objects of Sink class
        
        % Paralelization
        parallel logical = logical.empty;   % flag for parallelization of simulation
        workers  uint16  = uint16.empty;    % number of workers for parallelization
        
        % Neighbours search
        search Search = Search.empty;   % handle to object of Search class
        
        % Time integration
        scheme_trl  Scheme = Scheme.empty;   % handle to object of Scheme class for translation integration
        scheme_rot  Scheme = Scheme.empty;   % handle to object of Scheme class for rotation integration
        scheme_temp Scheme = Scheme.empty;   % handle to object of Scheme class for temperature integration
        
        % Time advancing
        auto_step logical = logical.empty;   % flag for computing time step automatically
        time_step double  = double.empty;    % time step value
        max_time  double  = double.empty;    % maximum simulation time
        time      double  = double.empty;    % current simulation time
        step      double  = double.empty;    % current simulation step (double to perform NaN operations in frequency checks)
        
        % Elapsed time control (real analysis time)
        start_time double  = double.empty;   % starting elapsed time for current analysis run
        total_time double  = double.empty;   % total elapsed time for all analysis runs
        
        % Output generation
        path_out   string    = string.empty;      % path to output folder
        save_ws    logical   = logical.empty;     % flag for saving workspace into a storage file
        result     Result    = Result.empty;      % handle to object of Result class
        animations Animation = Animation.empty;   % handles to objects of Animation class
        graphs     Graph     = Graph.empty;       % handles to objects of Graph class
        print      Print     = Print.empty;       % handle to object of Print class
        
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
        function initOutputVars(this)
            this.nprog = this.nprog * this.max_time / 100; % convert to time per print
            this.nout  = this.max_time / this.nout;        % convert to time per output
            this.tprog = this.nprog;
            this.tout  = this.nout;
        end
        
        %------------------------------------------------------------------
        function printProgress(this)
            if (this.time >= this.tprog)
                fprintf('\n%.1f%%: time %.3f, step %d',100*this.time/this.max_time,this.time,this.step);
                this.tprog = this.tprog + this.nprog - 10e-15; % tollerance to deal with precision issues
            end
        end
        
        %------------------------------------------------------------------
        % Object must be called 'drv' here to load it from storage file.
        function storeResults(drv)
            if (drv.time >= drv.tout)
                if (drv.save_ws)
                    drv.createOutFolder();
                    save(strcat(drv.path_out,drv.name));
                    drv.total_time = drv.start_time + toc;
                end
                if (~isempty(drv.print))
                    drv.print.execute(drv);
                end
                drv.tout = drv.tout + drv.nout - 10e-10; % tollerance to deal with precision issues
                drv.result.updateIndex();
                drv.store = true;
            else
                drv.store = false;
            end
        end
        
        %------------------------------------------------------------------
        function storeResultsFinal(this)
            if (this.result.idx < length(this.result.times))
                this.result.updateIndex();
                this.result.storeTime(this);
                this.result.storeAvgVelocity(this);
                this.result.storeExtVelocity(this);
                this.result.storeAvgAcceleration(this);
                this.result.storeExtAcceleration(this);
                this.result.storeAvgTemperature(this);
                this.result.storeExtTemperature(this);
                this.result.storeTotalHeatRate(this);
                for i = 1:this.n_particles
                    p = this.particles(i);
                    this.result.storeParticleProp(p);
                    this.result.storeParticlePosition(p);
                    this.result.storeParticleTemperature(p);
                    this.result.storeParticleForce(p);
                    this.result.storeParticleVelocity(p);
                    this.result.storeParticleAcceleration(p);
                    this.result.storeParticleHeatRate(p);
                end
                for i = 1:this.n_walls
                    w = this.walls(i);
                    this.result.storeWallPosition(w);
                    this.result.storeWallTemperature(w);
                end
                if (~isempty(this.print))
                    this.print.execute(this);
                end
            end
        end
        
        %------------------------------------------------------------------
        function setVoronoiDiagram(this)
            % Assumption: walls are ignored
            try
                [this.vor_vtx,this.vor_idx] = voronoiDiagram(delaunayTriangulation([this.particles.coord]'));
            catch
                fprintf(2,'Could not build Voronoi diagram in step %d\n',this.step);
            end
        end
        
        %------------------------------------------------------------------
        function setGlobalVol(this)
            % Assumption: in-plane projection area (unity depth)
            vol = area(alphaShape([this.particles.coord]',this.alpha));
            
            % Avoid null volume (aligned particles)
            % Assumption: set total particle volume (area) when volume is null
            if (vol ~= 0)
                this.vol_domain = vol;
            else
                if (isempty(this.cross_particle))
                    this.cross_particle = sum([this.particles.cross]);
                end
                this.vol_domain = this.cross_particle;
            end
        end
        
        %------------------------------------------------------------------
        function setGlobalPorosity(this)
            if (isempty(this.vol_domain))
                this.setGlobalVol();
            else
                % Assumption: total volume of particles computed as the
                % in-plane cross-sectional area (unity depth)
                this.porosity = 1 - this.cross_particle/this.vol_domain;
            end
        end
        
        %------------------------------------------------------------------
        function setTotalParticlesProps(this)
            this.surf_particle  = sum([this.particles.surface]);
            this.cross_particle = sum([this.particles.cross]);
            this.vol_particle   = sum([this.particles.volume]);
            this.mass_particle  = sum([this.particles.mass]);
        end
        
        %------------------------------------------------------------------
        function do = removeParticle(this,p)
            do = false;
            
            % Remove particles not respecting bbox
            if (this.has_bbox)
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
            if (this.has_sink)
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
        function erasePropsOfRemovedParticle(this)
            % Erase handles from global list
            this.particles(~isvalid(this.particles)) = [];
            this.n_particles = length(this.particles);
            
            % Erase handles from model parts
            for i = 1:this.n_mparts
                mp = this.mparts(i);
                mp.particles(~isvalid(mp.particles)) = [];
                mp.n_particles = length(mp.particles);
            end
            
            % Update total particles properties
            this.setTotalParticlesProps();
            
            % Attention:
            % To avoid additional computational costs, references to the
            % deleted particle from other particles (e.g. neighbohring
            % lists) are not removed.
        end
        
        %------------------------------------------------------------------
        function createOutFolder(this)
            if (~exist(this.path_out,'dir') ~= 7) % 7 = ID for folders
                warning off MATLAB:MKDIR:DirectoryExists
                mkdir(this.path_out)
                warning on MATLAB:MKDIR:DirectoryExists
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
                    this.animations(i).showAnimation();
                end
                fprintf('\n');
            end
        end
    end
end