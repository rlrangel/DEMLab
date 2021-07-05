%% ModelPart class
%
%% Description
%
%% Implementation
%
classdef ModelPart < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        name         string   = string.empty;     % identification name of model part
        n_particles  uint32   = uint32.empty;     % number of particles
        n_walls      uint32   = uint32.empty;     % number of walls
        particles    Particle = Particle.empty;   % handles to objects of Particle class
        walls        Wall     = Wall.empty;       % handles to objects of Wall class
    end
    
    %% Constructor method
    methods
        function this = ModelPart()
            this.n_particles = 0;
            this.n_walls     = 0;
        end
    end
    
    %% Public methods
    methods
        
    end
end
