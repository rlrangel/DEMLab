%% ConductionIndirect_VoronoiB class
%
%% Description
%
% This is a sub-class of the <conductionindirect.html ConductionIndirect>
% class for the implementation of the *Voronoi Polyhedra B* indirect heat
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
% * <https://doi.org/10.1016/j.ijheatmasstransfer.2018.12.005
% L. Chen, C. Wang, M. Moscardini, M. Kamlah and S. Liu.
% A DEM-based heat transfer model for the evaluation of effective thermal conductivity of packed beds filled with stagnant fluid: Thermal contact theory and numerical simulation, _Int. J. Heat Mass Transfer_, 132:331-346, 2019>
% (extension to multi-sized particles)
%
% * <https://doi.org/10.1103/PhysRevE.65.041302
% R.Y. Yang, R.P. Zou and A.B. Yu.
% Voronoi tessellation of the packing of fine uniform spheres, _Phys. Rev. E_, 65:041302, 2012>
% (relationship between Voronoi diagram and porosity)
%
classdef ConductionIndirect_VoronoiB < ConductionIndirect
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        coeff double = double.empty;   % heat transfer coefficient
        core  double = double.empty;   % radius of isothermal core (ratio of particle radius)
    end
    
    %% Constructor method
    methods
        function this = ConductionIndirect_VoronoiB()
            this = this@ConductionIndirect(ConductionIndirect.VORONOI_B);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            this.core = 0.5;
        end
        
        %------------------------------------------------------------------
        function this = setFixParams(this,int,drv)
            this.coeff = this.heatTransCoeff(int,drv);
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,~,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalHeatRate(this,int,drv)
            if (isempty(this.coeff))
                q = this.heatTransCoeff(int,drv);
            else
                q = this.coeff;
            end
            this.total_hrate = q * (int.elem2.temperature-int.elem1.temperature);
        end
    end
    
    %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function q = heatTransCoeff(this,int,drv)
            if (int.elem1.radius == int.elem2.radius ||...
                int.kinemat.gen_type == int.kinemat.PARTICLE_WALL)
                % Assumption: Particle-Wall is treated as 2 equal size particles
                q = this.evalExpressionMonosize(int,drv);
            else
                q = this.evalExpressionMultisize(int,drv);
            end
        end
        
        %------------------------------------------------------------------
        function q = evalExpressionMonosize(this,int,drv)
            % Needed properties
            Rp = int.elem1.radius;
            Rc = int.kinemat.contact_radius;
            D  = int.kinemat.dist/2;
            ks = int.eff_conduct;
            kf = drv.fluid_conduct;
            c  = this.core;
            
            % Parameters
            rij = this.getConductRadius(int,drv,Rp);
            a   = (1/c - 1/Rp)/(2*ks) + 1/(kf*Rp);
            b   = 1/(kf*D);
            c0  = D / sqrt(rij^2 + D^2);
            c1  = D / sqrt(Rc^2  + D^2);
            
            % Heat transfer coeff
            q = pi * log((a-b*c0)/(a-b*c1)) / b;
        end
        
        %------------------------------------------------------------------
        function q = evalExpressionMultisize(this,int,drv)
            % Needed properties
            R1 = int.elem1.radius;
            R2 = int.elem2.radius;
            Rc = int.kinemat.contact_radius;
            d  = int.kinemat.dist;
            k1 = int.elem1.conduct;
            k2 = int.elem2.conduct;
            kf = drv.fluid_conduct;
            c  = this.core;
            An = int.kinemat.vedge^2 * pi / 4;
            
            % Parameters
            gamma1 = R1/d;
            gamma2 = R2/d;
            dgamma = gamma2 - gamma1;
            
            A = (k1+kf*(1/c-1))/(k1*gamma1);
            B = (k2+kf*(1/c-1))/(k2*gamma2);
            
            lambda = (1+dgamma*A)*(1-dgamma*B);
            
            delmax = 0.5 * (sqrt((4*An)/(pi*d^2*(1-dgamma^2))+1) - dgamma);
            delmin = 0.5 * (sqrt((4*Rc^2)/(d^2*(1-dgamma^2))+1) - dgamma);
            
            Xmax = ((A+B)*delmax + dgamma*B - 1) / sqrt(abs(lambda));
            Xmin = ((A+B)*delmin + dgamma*B - 1) / sqrt(abs(lambda));
            
            Y1 = (Xmax-Xmin) / (1-Xmax*Xmin);
            Y2 = (Xmax-Xmin) / (1+Xmax*Xmin);
            
            % Heat transfer coeff
            if (lambda > 0)
                q = pi * kf * d * (1-dgamma^2) * log(abs((1-Y1)/(1+Y1))) / (2*sqrt(abs(lambda)));
            elseif (lambda < 0)
                q = pi * kf * d * (1-dgamma^2) * atan(Y2) / (2*sqrt(abs(lambda)));
            else
                q = pi * kf * d * (1-dgamma^2) * (1/delmin-1/delmax) / (A+B);
            end
        end
        
        %------------------------------------------------------------------
        function r = getConductRadius(this,int,drv,Rp)
            if (this.method == this.VORONOI_DIAGRAM)
                r = int.kinemat.vedge/2;
            else
                if (this.method == this.POROSITY_GLOBAL)
                    por = drv.porosity;
                elseif (this.method == this.POROSITY_LOCAL && int.kinemat.gen_type == int.kinemat.PARTICLE_PARTICLE)
                    por = (int.elem1.porosity+int.elem2.porosity)/2; % Assumption: average porosity
                else
                    por = int.elem1.porosity; % Assumption: particle porosity only
                end
                r = 0.56 * Rp / (1-por)^(1/3);
            end
        end
    end
end