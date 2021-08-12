%% ConductionDirect_Pipe class
%
%% Description
%
% This is a sub-class of the <conductiondirect.html ConductionDirect>
% class for the implementation of the *Thermal Pipe* direct heat
% conduction model.
%
% This model assumes that heat is exchanged through a ficticious "thermal
% pipe" connecting both elements, and the discrete Fourier law governs the
% rate of heat transfer:
%
% $$Q = \frac{k.A}{d}\Delta T$$
%
% Where:
%
% $$k = \left ( R_{i}+R_{j} \right ) \left ( \frac{R_{i}}{k_{i}} + \frac{R_{j}}{k_{j}} \right )^{-1}$$
%
% $$A = \pi \left ( R_{c} \right )^{2}$$
%
% *Notation*:
%
% $k$: Thermal conductivity of particles _i_ and _j_
%
% $R$: Radius of particles _i_ and _j_
%
% $R_{c}$: Contact radius
%
% $d$: Distance between the center of the particles
%
% $\Delta T = T_{j}-T_{i}$: Temperature difference between elements _i_ and _j_
%
% *References*:
%
% * <https://doi.org/10.1007/s40430-020-02465-5
% O.D. Quintana-Ruiz and E.M.B. Campello.
% A coupled thermo?mechanical model for the simulation of discrete particle systems, _J. Braz. Soc. Mech. Sci. Eng._, 42:387, 2020>
%
classdef ConductionDirect_Pipe < ConductionDirect
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Contact parameters
        coeff double = double.empty;   % heat transfer coefficient
    end
    
    %% Constructor method
    methods
        function this = ConductionDirect_Pipe()
            this = this@ConductionDirect(ConductionDirect.PIPE);
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
            this.total_hrate = pi * int.avg_conduct * int.kinemat.contact_radius^2 *...
                              (int.elem2.temperature-int.elem1.temperature) / int.kinemat.dist;
        end
    end
end