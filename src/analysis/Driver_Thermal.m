%% Driver_Thermal class
%
%% Description
%
%% Implementation
%
classdef Driver_Thermal < Driver
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Driver_Thermal()
            this = this@Driver(Driver.THERMAL);
        end
    end
    
    %% Public methods
    methods
        
    end
end