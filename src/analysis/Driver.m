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
        MECHANICAL        = 1;
        THERMAL           = 2;
        THERMO_MECHANICAL = 3;
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Problem data
        name      = [];   % problem name
        type      = 0;    % flag for type of analysis
        dimension = 0;    % model dimension
        
        % Model components: total numbers
        n_mparts    = 0;   % number of model parts
        n_particles = 0;   % number of particles
        n_walls     = 0;   % number of walls
        
        % Model components: handle to objects
        mparts    = [];   % vector of objects of the ModelPart class
        particles = [];   % vector of objects of the Particle class
        walls     = [];   % vector of objects of the Wall class
        
        % Model limits
        bbox = [];   % object of BBox class
    end
    
    %% Constructor method
    methods
        function this = Driver(type)
            this.type = type;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end