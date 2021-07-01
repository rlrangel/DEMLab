%% ContactKinematics_PW class
%
%% Description
%
%% Implementation
%
classdef ContactKinematics_PW < ContactKinematics
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = ContactKinematics_PW()
            this = this@ContactKinematics(ContactKinematics.PARTICLE_WALL);
        end
    end
    
    %% Public methods
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
        function evalRelPosVel(this,interact)
            p = interact.elem1;
            w = interact.elem2;
            
            % Distance between centroids
            d = w.distanceFromParticle(p1);
            overlap = d - p.radius;
        end
    end
end