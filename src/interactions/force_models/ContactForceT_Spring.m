%% ContactForceT_Spring class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_Spring < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        spring_coeff double = double.empty;   % spring coefficient value
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Spring()
            this = this@ContactForceT(ContactForceT.SPRING);
        end
    end
    
    %% Public methods
    methods
        
    end
end