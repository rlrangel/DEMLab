%% AreaCorrect_MPMH class
%
%% Description
%
% This is a sub-class of the <areacorrect.html AreaCorrect> class for the
% implementation of the *Morris, Pannala, Ma, Hrenya* contact area
% correction model.
%
% This model computes the reduced radius of the contact area by applying
% two correction factors to adjust both the overestimated contact area and
% contact time, based on the Batchelor & O'Brien model:
%
% $$R_{c}' = \left(\frac{F_{n}R_{eff}}{E_{eff,0}}\right)^{1/3}\left(\frac{t_{c,0}}{t_{c}}\right)^{2/3}$$
%
% Where:
%
% $R_{c}'$: Reduced radius of contact area
%
% $R_{eff}$: Effective contact radius
%
% $E_{eff,0}$: Effective Young modulus with the real value
%
% $F_{n}$: Normal contact force
%
% $t_{c}$: Contact duration
%
% $t_{c,0}$: Contact duration computed with real properties values
%
% *References*:
%
% * <https://doi.org/10.1002/aic.15331
% A.B. Morris, S. Pannala, Z. Ma, C.M. Hrenya.
% Development of soft-sphere contact models for thermal heat conduction in granular flows, _AIChE Journal_, 62(12):4526-4535, 2016>
%
classdef AreaCorrect_MPMH < AreaCorrect
    %% Constructor method
    methods
        function this = AreaCorrect_MPMH()
            this = this@AreaCorrect(AreaCorrect.MPMH);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = fixRadius(this,int)
            % Area correction
            % Assumption: time correction negleted (valid for static systems)
            if (~isempty(int.cforcen))
                fn = int.cforcen.total_force;
            else
                % Assumption: computed with Hertz model
                fn = 4 * sqrt(int.eff_radius) * int.eff_young * int.kinemat.ovlp_n^(3/2) / 3;
            end
            int.kinemat.contact_radius = (fn*int.eff_radius/int.eff_young0)^(1/3) * c_time;
        end
    end
end