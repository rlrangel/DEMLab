%% ConductionDirect_BOB class
%
%% Description
%
% This is a sub-class of the <ConductionDirect.html ConductionDirect>
% class for the implementation of the *Batchelor & O'Brien* direct heat
% conduction model.
%
% This model assumes a steady-state thermal flux between two smooth-elastic
% particles pressed together by a static compressionload forming a flat
% circle of contact, considering the Hertz theory. Furthermore, it is
% considered that particles are in vacuum, thus appropriate for when the
% particles thermal conductivity is much higher than the conductivity of
% the interstitial fluid.
%
% The rate of heat transfer is given by:
%
% $$Q = 4k_{eff}R_{c}\Delta T$$
%
% *Notation*:
%
% $k_{eff}$: Effective contact conductivity
%
% $R_{c}$: Contact radius
%
% $\Delta T = T_{j}-T_{i}$: Temperature difference between elements _i_ and _j_
%
% *References*:
%
% * <https://doi.org/10.1098/rspa.1977.0100
% G.K. Batchelor and R.W. O'Brien.
% Thermal or electrical conduction through a granular material, _Proceedings of the Royal Society of London_, 355(1682):313-333, 1977>
% (proposal)
%
% * <https://doi.org/10.1016/S0009-2509(99)00125-6
% G.J. Cheng, A.B. Yu and P. Zulli.
% Evaluation of effective thermal conductivity from the structure of a packed bed, _Chem. Eng. Sci._, 54(19):4199-4209, 1999>
% (alternative form)
%
classdef ConductionDirect_BOB < ConductionDirect
    %% Constructor method
    methods
        function this = ConductionDirect_BOB()
            this = this@ConductionDirect(ConductionDirect.BOB);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            
        end
        
        %------------------------------------------------------------------
        function this = setFixParams(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalHeatRate(this,int)
            this.total_hrate = 4 * int.eff_conduct * int.kinemat.contact_radius * (int.elem2.temperature-int.elem1.temperature);
        end
    end
end