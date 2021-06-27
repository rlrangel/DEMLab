%% Particle_Disk class
%
%% Description
%
%% Implementation
%
classdef Particle_Disk < Particle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Particle_Disk()
            this = this@Particle(Particle.DISK);
        end
    end
    
    %% Public methods
    methods
        
    end
end