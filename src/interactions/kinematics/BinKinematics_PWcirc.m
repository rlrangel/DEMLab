%% BinKinematics_PWcirc class
%
%% Description
%
%% Implementation
%
classdef BinKinematics_PWcirc < BinKinematics
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = BinKinematics_PWcirc()
            this = this@BinKinematics(BinKinematics.PARTICLE_WALL_CIRCLE);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setEffParams(~,interact)
            p  = interact.elem1;
            w  = interact.elem2;
            mp = p.material;
            mw = w.material;
            
            interact.eff_radius = p.radius;
            interact.eff_mass   = p.mass;
            if (isempty(mw))
                interact.eff_young = mp.young / (1 - mp.poisson^2);
            else
                interact.eff_young = 1 / ((1-mp.poisson^2)/mp.young + (1-mw.poisson^2)/mw.young);
            end
        end
        
        %------------------------------------------------------------------
        function [d,n] = distBtwSurf(~,p,w)
            n = w.center - p.coord;
            d = norm(n) - w.radius - p.radius;
        end
        
        %------------------------------------------------------------------
        function evalRelPosVel(this,interact,time_step)
            p = interact.elem1;
            w = interact.elem2;
            
            % Normal overlap and unit vector
            [d,n] = this.distBtwSurf(p,w);
            this.ovlp_n = -d;
            this.dir_n  = n;
            
            % Position of contact point relative to particle centroid
            c = (p.radius - this.ovlp_n) * this.dir_n;
            
            % Relative velocity at contact point (3D due to cross-product)
            w = cross([0;0;p.veloc_rot],[c(1);c(2);0]);
            vr = p.veloc_trl + w;
            
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