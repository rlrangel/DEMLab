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
% * <https://doi.org/10.1103/PhysRevE.65.041302
% R.Y. Yang, R.P. Zou and A.B. Yu.
% Voronoi tessellation of the packing of fine uniform spheres, _Phys. Rev. E_, 65:041302, 2012>
% (relationship between Voronoi diagram and porosity)
%
classdef ConductionIndirect_VoronoiA < ConductionIndirect
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        coeff   double = double.empty;   % heat transfer coefficient
        tol_abs double = double.empty;   % absolute tolerance for numerical integration
        tol_rel double = double.empty;   % relative tolerance for numerical integration
    end
    
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
            this.tol_abs = 1e-10;
            this.tol_rel = 1e-6;
        end
        
        %------------------------------------------------------------------
        function this = setFixParams(this,int)
            if (int.elem1.radius == int.elem2.radius ||...
                int.kinemat.gen_type == int.kinemat.PARTICLE_WALL)
                % Assumption: Particle-Wall is treated as 2 equal size particles
                this.coeff = this.evalIntegralMonosize(int);
            else
                this.coeff = this.evalIntegralMultisize(int);
            end
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalHeatRate(this,int)
            if (isempty(this.coeff))
                if (int.elem1.radius == int.elem2.radius ||...
                    int.kinemat.gen_type == int.kinemat.PARTICLE_WALL)
                    % Assumption: Particle-Wall is treated as 2 equal size particles
                    q = this.evalIntegralMonosize(int);
                else
                    q = this.evalIntegralMultisize(int);
                end
            else
                q = this.coeff;
            end
            this.total_hrate = q * (int.elem2.temperature-int.elem1.temperature);
        end
    end
    
    %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function y = evalIntegralMonosize(~,int)
            % Needed properties
            Rp  = int.elem1.radius;
            Rc  = int.kinemat.contact_radius;
            D   = int.kinemat.dist/2;
            ks  = int.eff_conduct;
            kf  = 1;
            por = 0.5;
            
            % Parameters
            rij = 0.56 * Rp / (1-por)^(1/3);
            rsf = Rp * rij / sqrt(rij^2 + D^2);            
            
            % Evaluate integral numerically
            fun = @(r) 2*pi*r / ((sqrt(Rp^2-r.^2) - r*D/rij)/ks + 2*(D - sqrt(Rp^2-r.^2))/kf);
            y = integral(fun,Rc,rsf,'ArrayValued',true,'AbsTol',this.tol_abs,'RelTol',this.tol_rel);
        end
        
        %------------------------------------------------------------------
        function y = evalIntegralMultisize(~,int)
            % Needed properties
            R1  = int.elem1.radius;
            R2  = int.elem2.radius;
            Rc  = int.kinemat.contact_radius;
            d   = int.kinemat.dist;
            k1  = int.elem1.conduct;
            k2  = int.elem2.conduct;
            kf  = 1;
            por = 0.5;
            
            % Parameters
            if (int.kinematic.is_contact)
                D1 = sqrt(R1^2-Rc^2);
            else
                D1 = (R1^2 - R2^2 + d^2) / (2*d);
            end
            D2 = d - D1;
            
            ri = 0.56 * ((R1+R2)/2) / (1-por)^(1/3); % Assumption: average radius
            if (R1 <= R2)
                rsf = R1*ri / sqrt(ri^2+D1^2);
            else
                rsf = R2*ri / sqrt(ri^2+D2^2);
            end
            rj = D2*rsf / sqrt(R2^2-rsf^2);
            
            % Evaluate integral numerically
            fun = @(r) 2*pi*r / ((sqrt(R1^2-r^2)-r*D1/ri)/k1 + (sqrt(R2^2-r^2)-r*D2/rj)/k2 + (d-sqrt(R1^2-r^2)-sqrt(R2^2-r^2))/kf);
            y = integral(fun,Rc,rsf,'ArrayValued',true,'AbsTol',this.tol_abs,'RelTol',this.tol_rel);
        end
    end
end