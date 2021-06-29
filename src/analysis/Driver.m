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
        
        % Model components: handle to objects
        mparts    ModelPart = ModelPart.empty;   % vector of objects of the ModelPart class
        particles Particle  = Particle.empty;    % vector of objects of the Particle class
        walls     Wall      = Wall.empty;        % vector of objects of the Wall class
        interacts Interact  = Interact.empty;    % vector of objects of the Interact class
        materials Material  = Material.empty;    % vector of objects of the Material class
        
        % Model limits
        bbox BBox = BBox.empty;   % object of BBox class
        sink Sink = Sink.empty;   % vector of objects of the Sink class
        
        % Paralelization
        parallel logical = logical.empty;   % flag for parallelization of simulation
        workers  uint16  = uint16.empty;    % number of workers for parallelization
        
        % Neighbours search
        search Search = Search.empty;   % object of Search object
        
        % Time advancing
        auto_step logical = logical.empty;   % flag for automatic time step
        time_step double  = double.empty;    % time step value
        max_time  double  = double.empty;    % maximum simulation time
        max_step  uint32  = uint32.empty;    % maximum step value allowed
        time      double  = double.empty;    % current simulation time
        step      uint32  = uint32.empty;    % current simulation step
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
        applyDefaultProps(this);
    end
    
    %% Public methods
    methods
        
    end
end