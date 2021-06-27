%% PC_Linear class
%
%% Description
%
%% Implementation
%
classdef PC_Linear < PC
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = PC_Linear()
            this = this@PC(PC.LINEAR);
        end
    end
    
    %% Public methods
    methods
        
    end
end