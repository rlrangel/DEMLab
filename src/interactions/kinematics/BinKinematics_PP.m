%% BinKinematics_PP class
%
%% Description
%
%% Implementation
%
classdef BinKinematics_PP < BinKinematics
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = BinKinematics_PP()
            this = this@BinKinematics(BinKinematics.PARTICLE_PARTICLE);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setEffParams(~,interact)
            p1 = interact.elem1;
            p2 = interact.elem2;
            m1 = p1.material;
            m2 = p2.material;
            
            interact.eff_radius = p1.radius * p2.radius / (p1.radius + p2.radius);
            interact.eff_mass   = p1.mass   * p2.mass   / (p1.mass   + p2.mass);
            interact.eff_young  = 1 / ((1-m1.poisson^2)/m1.young + (1-m2.poisson^2)/m2.young);
        end
        
        %------------------------------------------------------------------
        function [d,n] = distBtwSurf(~,p1,p2)
            n = p2.coord - p1.coord;
            d = norm(n) - p1.radius - p2.radius;
        end
        
        %------------------------------------------------------------------
        function evalRelPosVel(this,interact,time_step)
            p1 = interact.elem1;
            p2 = interact.elem2;
            
            % Direction between centroids
            n = p2.coord-p1.coord;
            
            % Distance between centroids
            d = norm(n);
            
            % Normal unit vector
            this.dir_n = n / d;
            
            % Normal overlap
            this.ovlp_n = p1.radius + p2.radius - d;
            
            % Positions of contact point relative to centroids
            c1 =  (p1.radius - this.ovlp_n/2) * this.dir_n;
            c2 = -(p2.radius - this.ovlp_n/2) * this.dir_n;
            
            % Velocities at contact point (3D due to cross-product)
            w1 = cross([0;0;p1.veloc_rot],[c1(1);c1(2);0]);
            w2 = cross([0;0;p2.veloc_rot],[c2(1);c2(2);0]);
            vc1 = p1.veloc_trl + w1;
            vc2 = p2.veloc_trl + w2;
            
            % Relative velocity at contact point
            vr = vc1 - vc2;
            
            % Normal overlap rate of change
            this.vel_n = dot(vr,this.dir_n);
            
            % Normal relative velocity
            vn = this.vel_n * this.dir_n;
            
            % Tangential relative velocity
            vt = vr - vn;
            
            % Tangential unit vector
            this.dir_t = vt / norm(vt);
            
            % Tangential overlap rate of change
            this.vel_t = dot(vr,this.dir_t);
            
            % Tangential overlap
            this.ovlp_t = this.ovlp_t + this.vel_t * time_step;
        end
    end
end