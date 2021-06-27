%% ModelPart class
%
%% Description
%
%% Implementation
%
classdef ModelPart < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        name         = [];   % identification name of model part
        
        n_particles  = 0;    % number of particles
        n_walls      = 0;    % number of walls
        
        id_particles = [];   % vector of particles IDs
        id_walls     = [];   % vector of walls IDs
        
        particles    = [];   % vector of objects of the Particle class
        walls        = [];   % vector of objects of the Wall class
    end
    
    %% Constructor method
    methods
        function this = ModelPart()
            
        end
    end
    
    %% Public methods
    methods
        
    end
end
