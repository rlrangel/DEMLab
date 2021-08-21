%% ConductionIndirect_SurrLayer class
%
%% Description
%
% This is a sub-class of the <conductionindirect.html ConductionIndirect>
% class for the implementation of the *Surrounding Layer* indirect heat
% conduction model.
%
% DESCRIPTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
classdef ConductionIndirect_SurrLayer < ConductionIndirect
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        coeff    double = double.empty;   % heat transfer coefficient
        layer    double = double.empty;   % surrounding fluid layer thickness (ratio of particle radius)
        dist_min double = double.empty;   % minimum separation distance of surfaces
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
            this.layer    = ;
            this.dist_min = ;
        end
        
        %------------------------------------------------------------------
        function this = setFixParams(this,int,drv)
            this.coeff = this.heatTransCoeff(int,drv);
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,int,drv)
            
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
                q = this.evalIntegralMonosize(int,drv);
            else
                q = this.evalIntegralMultisize(int,drv);
            end
        end
        
        %------------------------------------------------------------------
        function q = evalIntegralMonosize(this,int,drv)
            
        end
        
        %------------------------------------------------------------------
        function q = evalIntegralMultisize(this,int,drv)
            % Needed properties
            R1 = int.elem1.radius;
            R2 = int.elem2.radius;
            d  = int.kinemat.dist;
            S  = this.dist_min;
            L  = this.layer;
            L1 = L*R1;
            L2 = L*R2;
            Ri = min(R1,R2);
            Rj = max(R1,R2);
            
            % Parameters
            Rf = sqrt((Rj+)^2 - ()^2);
            
            % Evaluate integral numerically
            fun = @(r) 2*pi*r / max();
            try
                q = kf * integral(fun,Rc,rsf,'ArrayValued',true,'AbsTol',this.tol_abs,'RelTol',this.tol_rel);
            catch
                q = 0;
            end
        end
    end
end