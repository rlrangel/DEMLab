%% BinKinematics_SphereSphere class
%
%% Description
%
% This is a sub-class of the <binkinematics.html BinKinematics> class for
% the implementation of the *Sphere-Sphere* binary kinematics for
% particle-particle interactions.
%
% 
%
% References:
%
% * 
%
classdef BinKinematics_SphereSphere < BinKinematics
    %% Constructor method
    methods
        function this = BinKinematics_SphereSphere()
            this = this@BinKinematics(BinKinematics.SPHERE_SPHERE);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setEffParams(~,int)
            p1 = int.elem1;
            p2 = int.elem2;
            m1 = p1.material;
            m2 = p2.material;
            
            int.eff_radius  = p1.radius * p2.radius / (p1.radius + p2.radius);
            int.eff_mass    = p1.mass   * p2.mass   / (p1.mass   + p2.mass);
            if (~isempty(m1.young) && ~isempty(m1.poisson) &&...
                ~isempty(m2.young) && ~isempty(m2.poisson))
                int.eff_young = 1 / ((1-m1.poisson^2)/m1.young + (1-m2.poisson^2)/m2.young);
            end
            if (~isempty(m1.shear) && ~isempty(m1.poisson) &&...
                ~isempty(m2.shear) && ~isempty(m2.poisson))
                int.eff_shear = 1 / ((2-m1.poisson^2)/m1.shear + (2-m2.poisson^2)/m2.shear);
            end
            if (~isempty(m1.poisson) && ~isempty(m2.poisson))
                int.eff_poisson = (m1.poisson + m2.poisson) / 2;
            end
            if (~isempty(m1.conduct) && ~isempty(m2.conduct))
                int.eff_conduct = m1.conduct * m2.conduct / (m1.conduct + m2.conduct);
            end
        end
        
        %------------------------------------------------------------------
        function this = setRelPos(this,p1,p2)
            this.dir   = p2.coord - p1.coord;
            this.dist  = norm(this.dir);
            this.separ = this.dist - p1.radius - p2.radius;
        end
        
        %------------------------------------------------------------------
        function this = setOverlaps(this,int,dt)
            p1 = int.elem1;
            p2 = int.elem2;
            
            % Normal overlap and unit vector
            this.ovlp_n = -this.separ;
            this.dir_n  =  this.dir / this.dist;
            
            % Positions of contact point relative to centroids
            c1 =  (p1.radius - this.ovlp_n/2) * this.dir_n;
            c2 = -(p2.radius - this.ovlp_n/2) * this.dir_n;
            
            % Velocities at contact point (3D due to cross-product)
            w1 = cross([0;0;p1.veloc_rot],[c1(1);c1(2);0]);
            w2 = cross([0;0;p2.veloc_rot],[c2(1);c2(2);0]);
            vc1 = p1.veloc_trl + w1(1:2);
            vc2 = p2.veloc_trl + w2(1:2);
            
            % Relative velocity at contact point
            vr = vc1 - vc2;
            
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
        function addContactForceToParticles(~,int)
            p1 = int.elem1;
            p2 = int.elem2;
            
            % Total contact force from normal and tangential components
            total_force = int.cforcen.total_force + int.cforcet.total_force;
            
            % Add total contact force to particles considering appropriate sign
            p1.force = p1.force + total_force;
            p2.force = p2.force - total_force;
        end
        
        %------------------------------------------------------------------
        function addContactTorqueToParticles(this,int)
            p1 = int.elem1;
            p2 = int.elem2;
            
            % Tangential force vector for each particle
            ft1 =  int.cforcet.total_force;
            ft2 = -ft1;
            
            % Lever arm for each particle
            l1 =  (p1.radius-this.ovlp_n/2) * this.dir_n;
            l2 = -(p2.radius-this.ovlp_n/2) * this.dir_n;
            
            % Contact torque from tangential force (3D due to cross-product)
            torque1 = cross([l1(1);l1(2);0],[ft1(1);ft1(2);0]);
            torque2 = cross([l2(1);l2(2);0],[ft2(1);ft2(2);0]);
            torque1 = torque1(3);
            torque2 = torque2(3);
            
            % Add contact torque to particles considering appropriate sign
            p1.torque = p1.torque + torque1;
            p2.torque = p2.torque + torque2;
        end
        
        %------------------------------------------------------------------
        function addContactConductionToParticles(~,int)
            p1 = int.elem1;
            p2 = int.elem2;
            
            % Add contact conduction heat rate to particles considering appropriate sign
            p1.heat_rate = p1.heat_rate + int.cconduc.total_hrate;
            p2.heat_rate = p2.heat_rate - int.cconduc.total_hrate;
        end
    end
end