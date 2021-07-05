%% BinKinematics_PWlin (Particle-Line Wall) class
%
%% Description
%
%% Implementation
%
classdef BinKinematics_PWlin < BinKinematics
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = BinKinematics_PWlin()
            this = this@BinKinematics(BinKinematics.PARTICLE_WALL_LINE);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setEffParams(~,int)
            p  = int.elem1;
            w  = int.elem2;
            mp = p.material;
            mw = w.material;
            
            int.eff_radius = p.radius;
            int.eff_mass   = p.mass;
            if (isempty(mw))
                int.eff_young = mp.young / (1 - mp.poisson^2);
            else
                int.eff_young = 1 / ((1-mp.poisson^2)/mp.young + (1-mw.poisson^2)/mw.young);
            end
            if (~isempty(mp.conduct))
                int.eff_conduct = mp.conduct;
            end
        end
        
        %------------------------------------------------------------------
        function this = setRelPos(this,p,w)
            % Needed properties
            P = p.coord;
            A = w.coord_ini;
            B = w.coord_end;
            M = B - A;
            
            % Running parameter at the orthogonal intersection
            t = dot(M,P-A)/w.len^2;
            
            % Normal direction from particle to wall
            if (t <= 0)
                this.dir = A-P;
            elseif (t >= 1)
                this.dir = B-P;
            else
                this.dir = (A + t * M) - P;
            end
            
            % Distance between particle surface and line segment
            this.dist  = norm(this.dir);
            this.separ =  this.dist - p.radius;
        end
        
        %------------------------------------------------------------------
        function this = setOverlaps(this,int,dt)
            p = int.elem1;
            
            % Normal overlap and unit vector
            this.ovlp_n = -this.separ;
            this.dir_n  =  this.dir / this.dist;
            
            % Position of contact point relative to particle centroid
            c = (p.radius - this.ovlp_n) * this.dir_n;
            
            % Relative velocity at contact point (3D due to cross-product)
            w = cross([0;0;p.veloc_rot],[c(1);c(2);0]);
            vr = p.veloc_trl + w(1:2);
            
            % Normal overlap rate of change
            this.vel_n = dot(vr,this.dir_n);
            
            % Normal relative velocity
            vn = this.vel_n * this.dir_n;
            
            % Tangential relative velocity
            vt = vr - vn;
            
            % Tangential unit vector
            if (any(vt))
                this.dir_t = vt / norm(vt);
            else
                this.dir_t = [0;0];
            end
            
            % Tangential overlap rate of change
            this.vel_t = dot(vr,this.dir_t);
            
            % Tangential overlap
            this.ovlp_t = this.ovlp_t + this.vel_t * dt;
        end
        
        %------------------------------------------------------------------
        function this = setContactArea(this,int)
            % Needed properties
            r = int.elem1.radius;
            ovlp = this.ovlp_n;
            
            % Contact radius and area
            R2 = ovlp*(1+2*r);
            this.contact_radius = sqrt(R2);
            this.contact_area = pi * R2;
        end
        
        %------------------------------------------------------------------
        function addContactForceToParticles(~,int)
            p = int.elem1;
            
            % Total contact force from normal and tangential components
            total_force = int.cforcen.total_force + int.cforcet.total_force;
            
            % Add total contact force to particle considering appropriate sign
            p.force = p.force + total_force;
        end
        
        %------------------------------------------------------------------
        function addContactTorqueToParticles(this,int)
            p = int.elem1;
            f = int.cforcet.total_force;
            
            % Lever arm
            l = (p.radius-this.ovlp_n/2) * this.dir_n;
            
            % Contact torque from tangential force (3D due to cross-product)
            torque = cross([l(1);l(2);0],[f(1);f(2);0]);
            
            % Add contact torque to particle
            p.torque = p.torque + torque(3);
        end
        
        %------------------------------------------------------------------
        function addContactConductionToParticles(~,int)
            % Add contact conduction heat rate to particle considering appropriate sign
            p = int.elem1;
            p.heat_rate = p.heat_rate + int.cconduc.total_hrate;
        end
    end
end