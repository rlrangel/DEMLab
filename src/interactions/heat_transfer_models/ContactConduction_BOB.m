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
    
    %% Public methods
    methods
        
    end
end