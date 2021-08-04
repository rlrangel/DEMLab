%% ContactConduction_BOB class
%
%% Description
%
% This is a sub-class of the <contactconduction.html ContactConduction>
% class for the implementation of the *Batchelor & O'Brien* contact heat
% conduction model.
%
% 
%
% References:
%
% * 
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