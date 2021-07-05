%% Result class
%
%% Description
%
%% Implementation
%
classdef Result < handle
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of particle results
        MOTION = int8(1);
    end
    
    %% Public properties: Flags for required results
    properties (SetAccess = public, GetAccess = public)
        motion = logical(false);
    end
    
    %% Public properties: Results storage
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Result()
            
        end
    end
    
    %% Public methods
    methods
        
    end
end