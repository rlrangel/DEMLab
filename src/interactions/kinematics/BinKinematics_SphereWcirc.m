%% BinKinematics_SphereWcirc class
%
%% Description
%
% This is a sub-class of the <binkinematics.html BinKinematics> class for
% the implementation of the *Sphere-Wall Circle* binary kinematics for
% particle-wall interactions of types
% <particle_sphere.html Particle Sphere> and
% <wall_circ.html Wall Circle>.
%
classdef BinKinematics_SphereWcirc < BinKinematics
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        inside logical = logical.empty;   % flag for particle inside the circular wall
    end
    
    %% Constructor method
    methods
        function this = BinKinematics_SphereWcirc()
            this = this@BinKinematics(BinKinematics.PARTICLE_WALL,BinKinematics.SPHERE_WALL_CIRCLE);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setEffParams(~,int)
            p  = int.elem1;  w  = int.elem2;
            mp = p.material; mw = w.material;
            
            int.eff_radius = p.radius;
            int.eff_mass   = p.mass;
            
            % Wall with no material
            if (isempty(mw))
                if (~isempty(mp.young) && ~isempty(mp.poisson))
                    int.eff_young = mp.young / (1 - mp.poisson^2);
                end
                if (~isempty(mp.shear) && ~isempty(mp.poisson))
                    int.eff_shear = mp.shear / (2 - mp.poisson^2);
                end
                if (~isempty(mp.poisson))
                    int.avg_poisson = mp.poisson;
                end
                if (~isempty(mp.conduct))
                    int.eff_conduct = mp.conduct;
                    int.avg_conduct = mp.conduct;
                end
                
            % Wall with material
            else
                if (~isempty(mp.young) && ~isempty(mp.poisson) && ~isempty(mw.young) && ~isempty(mw.poisson))
                    int.eff_young = 1 / ((1-mp.poisson^2)/mp.young + (1-mw.poisson^2)/mw.young);
                end
                if (~isempty(mp.shear) && ~isempty(mp.poisson) && ~isempty(mw.shear) && ~isempty(mw.poisson))
                    int.eff_shear = 1 / ((2-mp.poisson^2)/mp.shear + (2-mw.poisson^2)/mw.shear);
                end
                if (~isempty(mp.poisson) && ~isempty(mw.poisson))
                    int.avg_poisson = (mp.poisson + mw.poisson) / 2;
                end
                if (~isempty(mp.conduct) && ~isempty(mw.conduct))
                    int.eff_conduct = mp.conduct * mw.conduct / (mp.conduct + mw.conduct);
                    int.avg_conduct = mp.conduct;
                end
            end
        end
        
        %------------------------------------------------------------------
        function this = setRelPos(this,p,w)
            direction = p.coord - w.center;
            this.dist = norm(direction);
            
            % Set distance and surface separation
            d = this.dist;
            R = w.radius;
            r = p.radius;
            
            % particle inside circle
            if (d <= R)
                this.inside = true;
                this.dir    = direction;
                this.separ  = R - d - r;
                
            % particle outside circle
            else
                this.inside = false;
                this.dir    = -direction;
                this.separ  = d - R - r;
            end
        end
        
        %------------------------------------------------------------------
        function this = setOverlaps(this,int,dt)
            p = int.elem1; w = int.elem2;
            
            % Normal overlap and unit vector
            this.ovlp_n = -this.separ;
            this.dir_n  =  this.dir / this.dist;
            
            % Positions of contact point
            cp = (p.radius - this.ovlp_n) * this.dir_n;
            if (this.inside)
                cw = w.radius * this.dir_n;
            else
                cw = -w.radius * this.dir_n;
            end
            
            % Particle velocity at contact point (3D due to cross-product)
            wp  = cross([0;0;p.veloc_rot],[cp(1);cp(2);0]);
            vcp = p.veloc_trl + wp(1:2);
            
            % Wall velocity at contact point (3D due to cross-product)
            ww  = cross([0;0;w.veloc_rot],[cw(1);cw(2);0]);
            vcw = w.veloc_trl + ww(1:2);
            
            % Relative velocities
            this.vel_trl = vcp - vcw;
            this.vel_rot = wp(1:2);       % assumption: particle only
            this.vel_ang = p.veloc_rot;   % assumption: particle only
            
            % Normal overlap rate of change
            this.vel_n = dot(this.vel_trl,this.dir_n);
            
            % Normal relative velocity
            vn = this.vel_n * this.dir_n;
            
            % Tangential relative velocity
            vt = this.vel_trl - vn;
            
            % Tangential unit vector
            if (any(vt))
                this.dir_t = vt / norm(vt);
            else
                this.dir_t = [0;0];
            end
            
            % Tangential overlap rate of change
            this.vel_t = dot(this.vel_trl,this.dir_t);
            
            % Tangential overlap
            if (isempty(this.ovlp_t))
                this.ovlp_t = this.vel_t * dt;
            else
                this.ovlp_t = this.ovlp_t + this.vel_t * dt;
            end
        end
        
        %------------------------------------------------------------------
        function this = setContactArea(this,int)
            % Needed properties
            d    = this.dist;
            r1   = int.elem1.radius;
            r2   = int.elem2.radius;
            r1_2 = r1 * r1;
            r2_2 = r2 * r2;
            
            % Contact radius and area
            R2 = r1_2 - ((r1_2-r2_2+d^2)/(2*d))^2;
            this.contact_radius = sqrt(R2);
            this.contact_area = pi * R2;
        end
        
        %------------------------------------------------------------------
        function addContactForceNormalToParticles(~,int)
            int.elem1.force = int.elem1.force + int.cforcen.total_force;
        end
        
        %------------------------------------------------------------------
        function addContactForceTangentToParticles(~,int)
            int.elem1.force = int.elem1.force + int.cforcet.total_force;
        end
        
        %------------------------------------------------------------------
        function addContactTorqueTangentToParticles(this,int)
            % Lever arm
            l = (int.elem1.radius-this.ovlp_n/2) * this.dir_n;
            
            % Torque from tangential contact force (3D due to cross-product)
            f = int.cforcet.total_force;
            torque = cross([l(1);l(2);0],[f(1);f(2);0]);
            
            % Add torque from tangential contact force to particle
            int.elem1.torque = int.elem1.torque + torque(3);
        end
        
        %------------------------------------------------------------------
        function addRollResistTorqueToParticles(~,int)
            int.elem1.torque = int.elem1.torque + int.rollres.torque;
        end
        
        %------------------------------------------------------------------
        function addDirectConductionToParticles(~,int)
            int.elem1.heat_rate = int.elem1.heat_rate + int.dconduc.total_hrate;
        end
        
        %------------------------------------------------------------------
        function addIndirectConductionToParticles(~,int)
            int.elem1.heat_rate = int.elem1.heat_rate + int.iconduc.total_hrate;
        end
    end
end