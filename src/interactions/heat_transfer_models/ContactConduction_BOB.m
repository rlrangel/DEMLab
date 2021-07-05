%% ContactConduction_BOB class
%
%% Description
%
%% Implementation
%
classdef ContactConduction_BOB < ContactConduction
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = ContactConduction_BOB()
            this = this@ContactConduction(ContactConduction.BATCHELOR_OBRIEN);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function this = setParameters(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalHeatRate(this,int)
            t1 = int.elem1.temperature;
            t2 = int.elem2.temperature;
            this.total_hrate = 4 * int.eff_conduct * int.kinemat.contact_radius * (t2-t1);
        end
    end
end