%% ModelPart class
%
%% Description
%
% This is a handle class for the definition of model parts.
%
% It stores the particles and walls belonging to a model part.
%
% Model parts are used to group together particles and / or walls, so that
% properties and conditions can be applied to several sifferent elements
% at once.
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
            this.setDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.n_particles = 0;
            this.n_walls     = 0;
        end
    end
end
