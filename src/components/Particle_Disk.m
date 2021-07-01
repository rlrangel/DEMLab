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
        
        %------------------------------------------------------------------
        function setSurface(this)
            this.surface = 4 * pi * this.radius^2;
        end
        
        %------------------------------------------------------------------
        function setVolume(this)
            this.volume = 4 * pi * this.radius^3/3;
        end
        
        %------------------------------------------------------------------
        function setMInertia(this)
            this.minertia = 2 * this.mass * this.radius^2/5;
        end
    end
end