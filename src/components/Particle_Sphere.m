%% Particle_Sphere class
%
%% Description
%
% This is a sub-class of the <particle.html Particle> class for the
% implementation of *Sphere* particles.
%
% A sphere particle behaves as a disk in a 2D model, but its properties are
% computed assuming that it is a 3D body.
%
classdef Particle_Sphere < Particle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Geometric properties
        radius double = double.empty;   % radius
    end
    
    %% Constructor method
    methods
        function this = Particle_Sphere()
            this = this@Particle(Particle.SPHERE);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            % Neighbours Interactions
            this.por_freq = NaN; % never compute
            
            % Behavior flags
            this.free_trl   = true;
            this.free_rot   = true;
            this.free_therm = true;
            
            % Forcing terms
            this.force     = [0;0];
            this.torque    = 0;
            this.heat_rate = 0;
            
            % Mechanical state variables
            this.veloc_trl = [0;0];
            this.veloc_rot = 0;
            this.accel_trl = [0;0];
            this.accel_rot = 0;
            
            % Thermal state variables
            this.temperature = 0;
            this.temp_change = 0;
        end
        
        %------------------------------------------------------------------
        function setCharLen(this)
            this.char_len = 2 * this.radius;
        end
        
        %------------------------------------------------------------------
        function setSurface(this)
            this.surface = 4 * pi * this.radius^2;
        end
        
        %------------------------------------------------------------------
        function setCrossSec(this)
            this.cross = pi * this.radius^2;
        end
        
        %------------------------------------------------------------------
        function setVolume(this)
            this.volume = 4 * pi * this.radius^3/3;
        end
        
        %------------------------------------------------------------------
        function setMInertia(this)
            this.minertia = 2 * this.mass * this.radius^2/5;
        end
        
        %------------------------------------------------------------------
        function [x1,y1,x2,y2] = getBBoxLimits(this)
            x1 = this.coord(1) - this.radius;
            y1 = this.coord(2) - this.radius;
            x2 = this.coord(1) + this.radius;
            y2 = this.coord(2) + this.radius;
        end
    end
end