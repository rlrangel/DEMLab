%% ConductionIndirect_SurrLayer class
%
%% Description
%
% This is a sub-class of the <conductionindirect.html ConductionIndirect>
% class for the implementation of the *Surrounding Layer* indirect heat
% conduction model.
%
% This model assumes that each particle is surrounded by a fluid layer, of
% a given thickness, through which heat is transferred  when it intersects
% the surface of another particle. In this case, heat flow paths are
% parallel to the to the normal direction between particles.
%
% For *multi-size particles*, the rate of heat transfer is given by:
%
% $$Q = \Delta T.k_{f} \int_{R_{c}}^{r_{sf}}\frac{2\pi.r.dr}{max\left(S,d-\sqrt{R_{i}^{2}-r^{2}}-\sqrt{R_{j}^{2}-r^{2}}\right)}$$
%
% Where:
%
% $$R_{k} = max(R_{i},R_{j})$$
%
% $$R_{l} = min(R_{i},R_{j})$$
%
% $$d_{cr} =\sqrt{\left(R_{k}+\delta_{f,k}\right)^{2} - R_{l}^{2}}$$
%
% If $d > d_{cr}$:
%
% $$r_{sf} = \sqrt{\left(R_{k}+\delta_{f,k}\right)^{2} - \left(\frac{\left(R_{k}+\delta_{f,k}\right)^{2}-R_{l}^{2}+d^{2}}{2d}\right)^{2}}$$
%
% If $d \leq d_{cr}$:
%
% $$r_{sf} = R_{l}$$
%
% For *mono-size particles*, the analytical solution for the integral is:
%
% $$Q = \Delta T 2\pi k_{eff}R_{p}\left((a+1)ln\left(\frac{\left|b-a-1\right|}{\left|a-c+1\right|}\right)+b-c\right)$$
%
% Where:
%
% $$a = \frac{d-2R_{p}}{R_{p}}$$
%
% $$b = \sqrt{1-r_{out}^{2}}$$
%
% $$c = \sqrt{1-r_{in}^{2}}$$
%
% $$\omega = \left(\frac{R_{p}+\delta_{f}}{R_{p}}\right)^{2}$$
%
% If $d > 2R_{p}+S$:
%
% $$r_{in} = 0$$
%
% If $d \leq 2R_{p}+S$:
%
% $$r_{in} = \sqrt{1-(S/R_{p}-a-1)^{2}}$$
%
% If $a > \sqrt{\omega-1}-1$:
%
% $$r_{out} = \sqrt{\omega-(a+1)^{2}}$$
%
% If $a \leq \sqrt{\omega-1}-1$:
%
% $$r_{out} = 1$$
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
% $S$: Minimum separation distance of surfaces (input)
%
% $\delta_{f}$: Thickness of a partilce's surrounding layer (input)
%
% *References*:
%
% * <https://www.semanticscholar.org/paper/DEM-SIMULATION-OF-CHAR-COMBUSTION-IN-A-FLUIDIZED-Rong-Horio/10229a5de283b99cc95948faecc7af95a699261b
% D. Rong and M. Horio.
% DEM simulation of char combustion in a fluidized bed, _2nd Intl. Conference on CFD in the Minerials and Process Industries_, 1999>
% (proposal)
%
% * <https://doi.org/10.33915/etd.4760
% J.M.H. Musser.
% Modeling of heat transfer and reactive chemistry for particles in gas-solid flow utilizing continuum-discrete methodology (CDM), PhD Thesis, 2011>
% (extension to multi-sized particles)
%
% * <https://doi.org/10.1016/j.ijheatmasstransfer.2015.06.004
% A.B. Morris, S. Pannala, Z. Ma and C.M. Hrenya.
% A conductive heat transfer model for particle flows over immersed surfaces, _Int. J. Heat Mass Transf._, 89:1277-1289, 2015>
% (analytical solution for mono-sized particles)
%
classdef ConductionIndirect_SurrLayer < ConductionIndirect
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        coeff    double = double.empty;   % heat transfer coefficient
        layer    double = double.empty;   % surrounding fluid layer thickness (ratio of particle radius)
        dist_min double = double.empty;   % minimum separation distance of surfaces
        tol_abs  double = double.empty;   % absolute tolerance for numerical integration
        tol_rel  double = double.empty;   % relative tolerance for numerical integration
    end
    
    %% Constructor method
    methods
        function this = ConductionIndirect_SurrLayer()
            this = this@ConductionIndirect(ConductionIndirect.SURROUNDING_LAYER);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            this.layer    = 0.4;
            this.dist_min = 2.75*1e-8;
            this.tol_abs  = 1e-10;
            this.tol_rel  = 1e-6;
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
                h = this.heatTransCoeff(int,drv);
            else
                h = this.coeff;
            end
            this.total_hrate = h * (int.elem2.temperature-int.elem1.temperature);
        end
    end
    
    %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function h = heatTransCoeff(this,int,drv)
            if (int.kinemat.gen_type == int.kinemat.PARTICLE_PARTICLE)
                h = this.evalIntegralParticleParticle(int,drv);
            else
                h = this.analyticSolutionParticleWall(int,drv);
            end
        end
        
        %------------------------------------------------------------------
        function h = evalIntegralParticleParticle(this,int,drv)
            % Needed properties
            Rc = int.kinemat.contact_radius;
            R1 = int.elem1.radius;
            R2 = int.elem2.radius;
            Ri = min(R1,R2);
            Rj = max(R1,R2);
            Lj = this.layer*Rj;
            kf = drv.fluid.conduct;
            d  = int.kinemat.dist;
            S  = this.dist_min;
            
            % Parameters
            RjLj2 = (Rj+Lj)^2;
            if (d <= sqrt(RjLj2-Ri^2))
                rsf = Ri;
            else
                rsf = sqrt(RjLj2-((RjLj2-Ri^2+d^2)/(2*d))^2);
            end
            
            % Evaluate integral numerically
            fun = @(r) 2*pi*r/max(S,d-sqrt(R1^2-r^2)-sqrt(R2^2-r^2));
            try
                h = kf * integral(fun,Rc,rsf,'ArrayValued',true,'AbsTol',this.tol_abs,'RelTol',this.tol_rel);
            catch
                h = 0;
            end
        end
        
        %------------------------------------------------------------------
        function h = analyticSolutionParticleWall(this,int,drv)
            % Needed properties
            Rp = int.elem1.radius;
            L  = this.layer*Rp;
            kf = drv.fluid.conduct;
            d  = int.kinemat.dist;
            S  = this.dist_min;
            
            % Parameters
            a = (d-Rp)/Rp;
            
            if (d > Rp+S)
                rin = 0;
            else
                rin = sqrt(1-(S/Rp-a-1)^2);
            end
            
            if (a > sqrt(((Rp+L)/Rp)^2-1)-1)
                rout = sqrt(((Rp+L)/Rp)^2-(a+1)^2);
            else
                rout = 1;
            end
            
            b = sqrt(1-rout^2);
            c = sqrt(1-rin^2);
            
            % Analytic solution of integral
            h = 2*pi*kf*Rp*((a+1)*log(abs(b-a-1)/abs(a-c+1))+b-c);
        end
    end
end