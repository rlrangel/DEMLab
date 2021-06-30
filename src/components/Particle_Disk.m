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
            this.applyDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.veloc_trl   = [0,0];
            this.veloc_rot   = 0;
            this.accel_trl   = [0,0];
            this.accel_rot   = 0;
            this.temperature = 0;
        end
    end
end