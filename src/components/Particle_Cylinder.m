%% Particle_Cylinder class
%
%% Description
%
% This is a sub-class of the <Particle.html Particle> class for the
% implementation of *Cylinder* particles.
%
% A cylinder particle behaves as a disk in a 2D model, but its properties are
% computed assuming that it is a 3D body.
%
classdef Particle_Cylinder < Particle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Geometric properties
        radius double = double.empty;   % radius
        len    double = double.empty;   % out-of-plane length
    end
    
    %% Constructor method
    methods
        function this = Particle_Cylinder()
            this = this@Particle(Particle.CYLINDER);
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
            % Assumption: lateral area only
            this.surface = 2 * pi * this.radius * this.len;
        end
        
        %------------------------------------------------------------------
        function setCrossSec(this)
            this.cross = pi * this.radius^2;
        end
        
        %------------------------------------------------------------------
        function setVolume(this)
            this.volume = pi * this.radius^2 * this.len;
        end
        
        %------------------------------------------------------------------
        function setMInertia(this)
            this.minertia = this.mass * this.radius^2/2;
        end
        
        %------------------------------------------------------------------
        function setLocalPorosity(this,por)
            % Set prescribed value
            if (~isempty(por))
                this.porosity = por;
                return;
            end
            
            % Vector of interacting particles
            % Assumption: porosity computed only with interacting neighbours
            P = [this,this.neigh_p(isvalid(this.neigh_p))];
            
            % Total volume of alpha-shape polygon with interacting particles centroids
            % Assumption: in-plane projection area (unity depth)
            vt = area(alphaShape([P.coord]',inf));
            
            % Avoid null volume (single particle or aligned particles)
            if (vt ~= 0)
                % Total volume of particles
                % Assumption:
                % 1. In-plane cross-sectional area (unity depth).
                % 2. Average particles radius and polygon interior angle.
                ravg = mean([P.radius]);
                vp   = (length(P)-2) * pi * ravg^2 / 2;
                
                % Local porosity
                this.porosity = 1 - vp/vt;
            else
                % Assumption: negleting particles volume
                this.porosity = 1;
            end
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