%% ContactConduction_BOB class
%
%% Description
%
% This is a sub-class of the <contactconduction.html ContactConduction>
% class for the implementation of the *Batchelor & O'Brien* contact heat
% conduction model.
%
% This model assumes a steady-state thermal flux between two smooth-elastic
% particles pressed together by a static compressionload forming a flat
% circle of contact, considering the Hertz theory. Furthermore, it is
% considered that particles are in vacuum, thus appropriate for when the
% particles thermal conductivity is much higher than the conductivity of
% the interstitial fluid.
%
% The heat transfer is given by:
%
% $Q = 4k_{eff}R_{c}\Delta T$
%
% Where:
%
% $k_{eff}$: Effective contact conductivity
%
% $R_{c}$: Contact radius
%
% $\Delta T$: Temperature difference between elements
%
% References:
%
% * <https://doi.org/10.1098/rspa.1977.0100 G.K. Batchelor and R.W. OBrien. Thermal or electrical conduction through a granular material, _Proceedings of the Royal Society of London_, 355(1682):313-333, 1977>.
%
% * <https://doi.org/10.1016/S0009-2509(99)00125-6 G.J. Cheng, A.B. Yu and P. Zulli. Evaluation of effective thermal conductivity from the structure of a packed bed, _Chem. Eng. Sci._, 54(19):4199-4209, 1999>.
%
classdef ContactConduction_BOB < ContactConduction
    %% Constructor method
    methods
        function this = ContactConduction_BOB()
            this = this@ContactConduction(ContactConduction.BATCHELOR_OBRIEN);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            
        end
        
        %------------------------------------------------------------------
        function this = evalHeatRate(this,int)
            t1 = int.elem1.temperature;
            t2 = int.elem2.temperature;
            this.total_hrate = 4 * int.eff_conduct * int.kinemat.contact_radius * (t2-t1);
        end
    end
end