%% BinKinematics_CylinderWlin class
%
%% Description
%
% This is a sub-class of the <binkinematics.html BinKinematics> class for
% the implementation of the *Cylinder-Wall Line* binary kinematics for
% particle-wall interactions of types
% <particle_cylinder.html Particle Cylinder> and
% <wall_line.html Wall Line>.
%
classdef BinKinematics_CylinderWlin < BinKinematics
    %% Constructor method
    methods
        function this = BinKinematics_CylinderWlin()
            this = this@BinKinematics(BinKinematics.CYLINDER_WALL_LINE);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setEffParams(~,int)
            p  = int.elem1;
            w  = int.elem2;
            mp = p.material;
            mw = w.material;
            
            int.eff_radius = p.radius;
            int.eff_mass   = p.mass;
            
            % Wall with no material set
            if (isempty(mw))
                if (~isempty(mp.young) && ~isempty(mp.poisson))
                    int.eff_young = mp.young / (1 - mp.poisson^2);
                end
                if (~isempty(mp.shear) && ~isempty(mp.poisson))
                    int.eff_shear = mp.shear / (2 - mp.poisson^2);
                end
                if (~isempty(mp.poisson))
                    int.eff_poisson = mp.poisson;
                end
                
            % Wall with material set
            else
                if (~isempty(mp.young) && ~isempty(mp.poisson) &&...
                    ~isempty(mw.young) && ~isempty(mw.poisson))
                    int.eff_young = 1 / ((1-mp.poisson^2)/mp.young + (1-mw.poisson^2)/mw.young);
                end
                if (~isempty(mp.shear) && ~isempty(mp.poisson) &&...
                    ~isempty(mw.shear) && ~isempty(mw.poisson))
                    int.eff_shear = 1 / ((2-mp.poisson^2)/mp.shear + (2-mw.poisson^2)/mw.shear);
                end
                if (~isempty(mp.poisson) && ~isempty(mw.poisson))
                    int.eff_poisson = (mp.poisson + mw.poisson) / 2;
                end
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
            w = int.elem2;
            
            % Normal overlap and unit vector
            this.ovlp_n = -this.separ;
            this.dir_n  =  this.dir / this.dist;
            
            % Position of contact point
            cp = (p.radius - this.ovlp_n) * this.dir_n;
            cw = (p.coord+cp) - (w.coord_ini+w.coord_end)/2;
            
            % Particle velocity at contact point (3D due to cross-product)
            wp  = cross([0;0;p.veloc_rot],[cp(1);cp(2);0]);
            vcp = p.veloc_trl + wp(1:2);
            
            % Wall velocity at contact point (3D due to cross-product)
            ww  = cross([0;0;w.veloc_rot],[cw(1);cw(2);0]);
            vcw = w.veloc_trl + ww(1:2);
            
            % Relative velocity at contact point
            vr = vcp - vcw;
            
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
            l = int.elem1.len;
            ovlp = this.ovlp_n;
            
            % Contact radius and area
            r = sqrt(r^2 - (r-ovlp)^2);
            this.contact_radius = r;
            this.contact_area   = 2 * r * l;
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