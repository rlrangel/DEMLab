%% BinKinematics_SphereSphere class
%
%% Description
%
% This is a sub-class of the <binkinematics.html BinKinematics> class for
% the implementation of the *Sphere-Sphere* binary kinematics for
% particle-particle interactions of type
% <particle_sphere.html Particle Sphere>.
%
% <<kinematics_circles.png>>
%
classdef BinKinematics_SphereSphere < BinKinematics
    %% Constructor method
    methods
        function this = BinKinematics_SphereSphere(dir,dist,separ)
            this = this@BinKinematics(BinKinematics.PARTICLE_PARTICLE,BinKinematics.SPHERE_SPHERE);
            if (nargin == 3)
                this.dir   = dir;
                this.dist  = dist;
                this.separ = separ;
            end
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setEffParams(~,int)
            p1 = int.elem1;   p2 = int.elem2;
            m1 = p1.material; m2 = p2.material;
            
            % Effective and average parameters
            int.eff_radius = p1.radius * p2.radius / (p1.radius + p2.radius);
            int.eff_mass   = p1.mass   * p2.mass   / (p1.mass   + p2.mass);
            
            if (~isempty(m1.young) && ~isempty(m1.poisson) && ~isempty(m2.young) && ~isempty(m2.poisson))
                int.eff_young = 1 / ((1-m1.poisson^2)/m1.young + (1-m2.poisson^2)/m2.young);
            end
            if (~isempty(m1.shear) && ~isempty(m1.poisson) && ~isempty(m2.shear) && ~isempty(m2.poisson))
                int.eff_shear = 1 / ((2-m1.poisson^2)/m1.shear + (2-m2.poisson^2)/m2.shear);
            end
            if (~isempty(m1.poisson) && ~isempty(m2.poisson))
                int.avg_poisson = (m1.poisson + m2.poisson) / 2;
            end
            if (~isempty(m1.conduct) && ~isempty(m2.conduct))
                int.eff_conduct = m1.conduct * m2.conduct / (m1.conduct + m2.conduct);
                int.avg_conduct = (p1.radius + p2.radius) / (p1.radius/m1.conduct + p2.radius/m2.conduct);
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
            p1 = int.elem1; p2 = int.elem2;
            
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
            
            % Relative velocities
            this.vel_trl = vc1 - vc2;
            this.vel_rot = w1(1:2) + w2(1:2);
            this.vel_ang = p1.veloc_rot - p2.veloc_rot;
            
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
            % (abs to avoid imag. numbers when particles are inside each other)
            R2 = abs(r1_2 - ((r1_2-r2_2+d^2)/(2*d))^2);
            this.contact_radius = sqrt(R2);
            this.contact_area = pi * R2;
        end
        
        %------------------------------------------------------------------
        function addContactForceNormalToParticles(~,int)
            int.elem1.force = int.elem1.force + int.cforcen.total_force;
            int.elem2.force = int.elem2.force - int.cforcen.total_force;
        end
        
        %------------------------------------------------------------------
        function addContactForceTangentToParticles(~,int)
            int.elem1.force = int.elem1.force + int.cforcet.total_force;
            int.elem2.force = int.elem2.force - int.cforcet.total_force;
        end
        
        %------------------------------------------------------------------
        function addContactTorqueTangentToParticles(this,int)            
            % Tangential force vector for each particle
            ft1 =  int.cforcet.total_force;
            ft2 = -ft1;
            
            % Lever arm for each particle
            l1 =  (int.elem1.radius-this.ovlp_n/2) * this.dir_n;
            l2 = -(int.elem2.radius-this.ovlp_n/2) * this.dir_n;
            
            % Torque from tangential contact force (3D due to cross-product)
            torque1 = cross([l1(1);l1(2);0],[ft1(1);ft1(2);0]);
            torque2 = cross([l2(1);l2(2);0],[ft2(1);ft2(2);0]);
            torque1 = torque1(3);
            torque2 = torque2(3);
            
            % Add torque from tangential contact force to particles
            int.elem1.torque = int.elem1.torque + torque1;
            int.elem2.torque = int.elem2.torque + torque2;
        end
        
        %------------------------------------------------------------------
        function addRollResistTorqueToParticles(~,int)
            int.elem1.torque = int.elem1.torque + int.rollres.torque;
            int.elem2.torque = int.elem2.torque + int.rollres.torque;
        end
        
        %------------------------------------------------------------------
        function addDirectConductionToParticles(~,int)
            int.elem1.heat_rate = int.elem1.heat_rate + int.dconduc.total_hrate;
            int.elem2.heat_rate = int.elem2.heat_rate - int.dconduc.total_hrate;
        end
        
        %------------------------------------------------------------------
        function addIndirectConductionToParticles(~,int)
            int.elem1.heat_rate = int.elem1.heat_rate + int.iconduc.total_hrate;
            int.elem2.heat_rate = int.elem2.heat_rate - int.iconduc.total_hrate;
        end
    end
end