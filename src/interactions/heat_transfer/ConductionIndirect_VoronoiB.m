%% ConductionIndirect_VoronoiB class
%
%% Description
%
% This is a sub-class of the <conductionindirect.html ConductionIndirect>
% class for the implementation of the *Voronoi Polyhedra B* indirect heat
% conduction model.
%
% This model assumes that the indirect heat conduction between two
% neighboring elements is restricted to the region delineated by the
% double pyramid whose apexes are the particles' centers and base is the
% Voronoi boundary plane shared by the particles' cells.
% For simplicity, the double pyramid is treated as a double tapered cone
% with the same base area _A_.
% In 2D, the Voronoi edge shared by the cells of both particles represents
% the diameter of the cone base.
%
% <<voronoi.png>>
%
% In model B, the following assumptions are made:
%
% * Conduction in the outer region of the cone (region B) is included.
% * Particles have an isothermal core of radius _rc_ with their
% representative temperature (input parameter).
% * Heat flow paths radiate from the cores' surfaces.
%
% For *mono-size particles*, the rate of heat transfer is given by:
%
% $$Q = \Delta T \frac{\pi}{b}ln\left(\frac{a-b.c_{0}}{a-b.c_{1}}\right)$$
%
% Where:
%
% $$a = \frac{1}{2k_{eff}}\left(\frac{1}{r_{c}}-\frac{1}{R_{p}}\right)+\frac{1}{k_{f}R_{p}}$$
%
% $$b = \frac{2}{k_{f}d}$$
%
% $$c_{0} = \frac{d}{2\sqrt{r_{ij}^{2}+d^{2}/4}}$$
%
% $$c_{1} = \frac{d}{2\sqrt{R_{c}^{2}+d^{2}/4}}$$
%
% For *multi-size particles*, the rate of heat transfer is given by:
%
% For $\Lambda > 0$:
%
% $Q = \Delta T \pi k_{f}d\left(1-\Delta\gamma^{2}\right)\left(2\sqrt{\left|\Lambda\right|}\right)^{-1}ln\left|(1-Y_{1})/(1+Y_{1})\right|$
%
% For $\Lambda < 0$:
%
% $Q = \Delta T \pi k_{f}d\left(1-\Delta\gamma^{2}\right)\left(2\sqrt{\left|\Lambda\right|}\right)^{-1}tg^{-1}(Y_{2})$
%
% For $\Lambda = 0$:
%
% $Q = \Delta T \pi k_{f}d\left(1-\Delta\gamma^{2}\right)\left(A+B\right)^{-1}\left(1/\delta_{min}-1/\delta_{max}\right)$
%
% Where:
%
% $$\Lambda = \left(1+\Delta\gamma A\right)\left(1-\Delta\gamma B\right)$$
%
% $$\Delta\gamma = \gamma_{j}-\gamma_{i}$$
%
% $$\gamma_{i} = R_{i}/d$$
%
% $$\gamma_{j} = R_{j}/d$$
%
% $$Y_{1} =\frac{X_{max}-X_{min}}{1-X_{max}X_{min}}$$
%
% $$Y_{2} =\frac{X_{max}-X_{min}}{1+X_{max}X_{min}}$$
%
% $$X_{max} =\frac{(A+B)\delta_{max}+\Delta\gamma B-1}{\sqrt{\left|\Lambda\right|}}$$
%
% $$X_{min} =\frac{(A+B)\delta_{min}+\Delta\gamma B-1}{\sqrt{\left|\Lambda\right|}}$$
%
% $$A = \frac{k_{i}+k_{f}\left(R_{i}/r_{c,i}-1\right)}{k_{i}\gamma_{i}}$$
%
% $$B = \frac{k_{j}+k_{f}\left(R_{j}/r_{c,j}-1\right)}{k_{j}\gamma_{j}}$$
%
% $$\delta_{max} = 0.5\left(\sqrt{1+\frac{4A}{\pi d^{2}\left(1-\Delta\gamma^{2}\right)}}-\Delta\gamma\right)$$
%
% $$\delta_{min} = 0.5\left(\sqrt{1+\frac{4R_{c}^{2}}{d^{2}\left(1-\Delta\gamma^{2}\right)}}-\Delta\gamma\right)$$
%
% In both cases, the heat transfer radius $r_{ij}$ depends on the shape and
% size of the Voronoi cells. There are 3 methods to obtain its value:
%
% * *1. Voronoi Diagram*:
%
% The Voronoi diagram is built in a given frequency, and the heat transfer
% radius is related to the volume _V_ and diameter _Le_ of the double
% tapered cone as:
%
% $$r_{ij} = \sqrt{\frac{3V}{\pi d}} = \frac{L_{e}}{2}$$
%
% * *2. Local Porosity*:
%
% It has been shown that the average size of the Voronoi cells is related
% to the porosity of the medium _e_, in such a way that the heat transfer
% radius can be computed as:
%
% $$r_{ij} = 0.56R_{p}\left(1-e\right)^{-1/3}$$
%
% In this method, instead of building the Voronoi diagram, the local
% porosity around each particle, considering its immediate neighbors,
% is computed and updated in a given frequency.
%
% * *3. Global Porosity*:
%
% In this method, the value of the average global porosity is directly
% provided and kept constant, or it is automatically computed by assuming
% that the total volume of the domain is obtained by the applying the
% <https://www.mathworks.com/help/matlab/ref/alphashape.html alpha-shape
% method> over all particles.
%
% *Notation*:
%
% $\Delta T = T_{j}-T_{i}$: Temperature difference between elements _i_ and _j_
%
% $R$: Radius of particles _i_ and _j_ (or _p_ when mono-size)
%
% $R_{c}$: Contact radius
%
% $d$: Distance between the center of the particles
%
% $k$: Thermal conductivity of particles _i_ and _j_, and interstitial fluid _f_
%
% $k_{eff}$: Effective contact conductivity
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
% A DEM-based heat transfer model for the evaluation of effective thermal conductivity of packed beds filled with stagnant fluid: Thermal contact theory and numerical simulation, _Int. J. Heat Mass Transf._, 132:331-346, 2019>
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
        method uint8  = uint8.empty;    % flag for type of method to compute voronoi cells size
        coeff  double = double.empty;   % heat transfer coefficient
        core   double = double.empty;   % radius of isothermal core (ratio of particle radius)
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
            if (int.kinemat.gen_type == int.kinemat.PARTICLE_WALL ||...
                int.elem1.radius == int.elem2.radius)
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
            kf = drv.fluid.conduct;
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
            kf = drv.fluid.conduct;
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