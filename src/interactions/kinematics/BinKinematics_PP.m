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
            if (~isempty(m1.conduct) && ~isempty(m2.conduct))
                interact.eff_conduct = m1.conduct * m2.conduct / (m1.conduct + m2.conduct);
            end
        end
        
        %------------------------------------------------------------------
        function setRelPos(this,p1,p2)
            this.dir   = p2.coord - p1.coord;
            this.dist  = norm(this.dir);
            this.separ = this.dist - p1.radius - p2.radius;
        end
        
        %------------------------------------------------------------------
        function evalOverlaps(this,interact,time_step)
            p1 = interact.elem1;
            p2 = interact.elem2;
            
            % Normal overlap and unit vector
            this.ovlp_n = -this.separ;
            this.dir_n  =  this.dir / this.dist;
            
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
        
        %------------------------------------------------------------------
        function addContactForceToParticles(~,interact)
            p1 = interact.elem1;
            p2 = interact.elem2;
            
            % Total contact force from normal and tangential components
            total_force = interact.contact_force_norm.total_force +...
                          interact.contact_force_tang.total_force;
            
            % Add total contact force to particles considering appropriate sign
            p1.force = p1.force + total_force;
            p1.force = p2.force - total_force;
        end
        
        %------------------------------------------------------------------
        function addContactTorqueToParticles(this,interact)
            p1 = interact.elem1;
            p2 = interact.elem2;
            
            % Tangential force vector for each particle
            ft1 =  interact.contact_force_tang.total_force;
            ft2 = -ft1;
            
            % Lever arm for each particle
            lever1 =  (p1.radius-this.ovlp_n/2) * this.dir_n;
            lever2 = -(p2.radius-this.ovlp_n/2) * this.dir_n;
            
            % Contact torque from tangential force (3D due to cross-product)
            torque1 = cross(lever1,ft1);
            torque2 = cross(lever2,ft2);
            torque1 = torque1(3);
            torque2 = torque2(3);
            
            % Add contact torque to particles considering appropriate sign
            p1.torque = p1.torque + torque1;
            p2.torque = p2.torque + torque2;
        end
        
        %------------------------------------------------------------------
        function addContactConductionToParticles(~,interact)
            p1 = interact.elem1;
            p2 = interact.elem2;
            
            % Add contact conduction heat rate to particles considering appropriate sign
            p1.heat_rate = p1.heat_rate + interact.contact_conduction.total_hrate;
            p1.heat_rate = p2.heat_rate - interact.contact_conduction.total_hrate;
        end
    end
end