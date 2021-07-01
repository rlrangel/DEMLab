%% ContactKinematics_PP class
%
%% Description
%
%% Implementation
%
classdef ContactKinematics_PP < ContactKinematics
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = ContactKinematics_PP()
            this = this@ContactKinematics(ContactKinematics.PARTICLE_PARTICLE);
        end
    end
    
    %% Public methods
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
        function evalRelPosVel(this,interact)
            p1 = interact.elem1;
            p2 = interact.elem2;
            
            % Distance between centroids
            n = p1.coord-p2.coord;
            d = norm(n);
            
            % Overlaps
            this.ovlp_norm = d - p1.radius - p2.radius;
            %this.ovlp_tang = time_step * tg_veloc;
            
            % Unit direction vectors
            this.dir_n = n / d;
            %this.dir_t = vt / abs(vt);
            
            % 
            
        end
    end
end