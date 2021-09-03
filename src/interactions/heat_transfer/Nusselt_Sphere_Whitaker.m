%% Nusselt_Sphere_Whitaker class
%
%% Description
%
% This is a sub-class of the <nusselt.html Nusselt>
% class for the implementation of the *Whitaker* correlation for computing
% the Nusselt number for a flow past a sphere.
%
% $$Nu = 2 + \left(0.4Re^{1/2}+0.06Re^{2/3}\right)Re^{2/5}\left(\frac{\mu_{f}}{\mu_{fs}}\right)^{1/4}$$
%
% *Notation*:
%
% $Re$: Reynolds number
%
% $Pr$: Prandtl number
%
% $\mu_{f}$: Fluid viscosity at fluid temperature
%
% $\mu_{fs}$: Fluid viscosity at particle surface temperature (assumed to be equal to the fluid temperature value)
%
% *References*:
%
% * <https://doi.org/10.1002/aic.690180219
% S. Whitaker.
% Forced convection heat transfer correlations for flow in pipes, past flat plates, single cylinders, single spheres, and for flow in packed beds and tube bundles, _AIChE Journal_, 18(2):361-371, 1972>
% (proposal)
%
classdef Nusselt_Sphere_Whitaker < Nusselt
    %% Constructor method
    methods
        function this = Nusselt_Sphere_Whitaker()
            this = this@Nusselt(Nusselt.SPHERE_WHITAKER);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function Nu = getValue(~,p,drv)
            % Prandtl number
            Pr = drv.fluid.Pr;
            
            % Reynolds number
            Re = drv.fluid.density * p.char_len * norm(drv.fluid_vel-p.veloc_trl) / drv.fluid.viscosity;
            
            % Nusselts correlation
            Nu = 2 + (0.4 * Re^(1/2) + 0.06 * Re^(2/3)) * Pr^(2/5);
        end
    end
end