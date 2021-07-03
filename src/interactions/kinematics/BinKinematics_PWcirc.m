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
            if (~isempty(mp.conduct))
                interact.eff_conduct = mp.conduct;
            end
        end
        
        %------------------------------------------------------------------
        function setRelPos(this,p,w)
            this.dir   = w.center - p.coord;
            this.dist  = norm(this.dir);
            this.separ = this.dist - p.radius - w.radius;
        end
        
        %------------------------------------------------------------------
        function evalOverlaps(this,interact,time_step)
            p = interact.elem1;
            
            % Normal overlap and unit vector
            this.ovlp_n = -this.separ;
            this.dir_n  =  this.dir / this.dist;
            
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
        
        %------------------------------------------------------------------
        function setContactArea(this,interact)
            % Needed properties
            d    = this.dist;
            r1   = interact.elem1.radius;
            r2   = interact.elem2.radius;
            r1_2 = r1 * r1;
            r2_2 = r2 * r2;
            
            % Contact radius and area
            R2 = r1_2 - ((r1_2-r2_2+d^2)/(2*d))^2;
            this.contact_radius = sqrt(R2);
            this.contact_area = pi * R2;
        end
    end
end