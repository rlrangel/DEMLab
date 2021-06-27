%% Particle class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef Particle < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of particle
        DISK = 1;
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type = 0;   % flag for type of particle
        id   = 0;   % identification number
        
        % Geometric properties
        radius = 0;
        
        % Current state
        coord  = [];   % coordinates of centroid
        orient = [];   % orientation angles
    end
    
    %% Constructor method
    methods
        function this = Particle(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        
    end
    
    %% Public methods
    methods
        
    end
end