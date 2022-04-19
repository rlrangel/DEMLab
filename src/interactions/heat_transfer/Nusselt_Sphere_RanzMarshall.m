%% Nusselt_Sphere_RanzMarshall class
%
%% Description
%
% This is a sub-class of the <Nusselt.html Nusselt>
% class for the implementation of the *Hanz & Marshall* correlation for
% computing the Nusselt number for a flow past a sphere.
%
% $$Nu = 2 + 0.6Re^{1/2}Pr^{1/3}$$
%
% *Notation*:
%
% $Re$: Reynolds number
%
% $Pr$: Prandtl number
%
% *References*:
%
% * W.E. Ranz and W.R. Marshall.
% Evaporation from Drops, _Chem Eng Prog_, 48:141-146, 1952.
% (proposal)
%
classdef Nusselt_Sphere_RanzMarshall < Nusselt
    %% Constructor method
    methods
        function this = Nusselt_Sphere_RanzMarshall()
            this = this@Nusselt(Nusselt.SPHERE_RANZ_MARSHALL);
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
            Nu = 2 + 0.6 * Re^(1/2) * Pr^(1/3);
        end
    end
end