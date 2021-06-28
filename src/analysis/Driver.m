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
        
        % Model components: handle to objects
        mparts    ModelPart = ModelPart.empty;   % vector of objects of the ModelPart class
        particles Particle  = Particle.empty;    % vector of objects of the Particle class
        walls     Wall      = Wall.empty;        % vector of objects of the Wall class
        
        % Model limits
        bbox BBox = BBox.empty;   % object of BBox class
        
        % Global conditions
        gravity double = double.empty;   % vector of gravity value components
    end
    
    %% Constructor method
    methods
        function this = Driver(type)
            if (nargin > 0)
                this.type = type;
            end
            this.n_mparts    = 0;
            this.n_particles = 0;
            this.n_walls     = 0;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end