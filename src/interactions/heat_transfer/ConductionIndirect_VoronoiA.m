%% ConductionIndirect_VoronoiA class
%
%% Description
%
% This is a sub-class of the <conductionindirect.html ConductionIndirect>
% class for the implementation of the *Voronoi Polyhedron A* indirect heat
% conduction model.
%
% DESCRIPTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%
% *References*:
%
% * <https://doi.org/10.1016/S0009-2509(99)00125-6
% G.J. Cheng, A.B. Yu and P. Zulli.
% Evaluation of effective thermal conductivity from the structure of a packed bed, _Chem. Eng. Sci._, 54(19):4199-4209, 1999>
% (proposal)
%
% * <https://doi.org/10.1016/S0009-2509(99)00125-6
% J. Gan, Z. Zhou and A. Yu.
% Particle scale study of heat transfer in packed and fluidized beds of ellipsoidal particles, _Chem. Eng. Sci._, 144:201-215, 2016>
% (extension to multi-sized particles)
%
classdef ConductionIndirect_VoronoiA < ConductionIndirect
    %% Constructor method
    methods
        function this = ConductionIndirect_VoronoiA()
            this = this@ConductionIndirect(ConductionIndirect.VORONOI_A);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalHeatRate(this,int)
            V  = 1;
            kf = 1;
            
            t1  = int.elem1.temperature;
            t2  = int.elem2.temperature;
            Rp  = int.elem1.radius;
            Rc  = int.kinemat.contact_radius;
            dij = int.kinemat.dist;
            H   = int.kinemat.separ/2;
            ks  = int.eff_conduct;
            
            rij = sqrt(3*V/(pi*dij));
            rsf = Rp * rij / sqrt(rij^2 + (Rp+H)^2);
            
            fun = @(r) 2*pi*r / ((sqrt(Rp^2-r.^2) - r*(Rp+H)/rij)/ks + 2*((Rp+H) - sqrt(Rp^2-r.^2))/kf);
            q = integral(fun,Rc,rsf,'ArrayValued',true,'AbsTol',1e-10,'RelTol',1e-6);
            
            this.total_hrate = q * (t2-t1);
        end
    end
end