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
        function setParameters(~,~)
            
        end
        
        %------------------------------------------------------------------
        function evalHeatRate(this,interact)
            t1 = interact.elem1.temperature;
            t2 = interact.elem2.temperature;
            this.total_hrate = 4 * interact.eff_conduct * interact.kinematics.contact_radius * (t2-t1);
        end
    end
end