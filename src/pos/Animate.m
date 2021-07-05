%% Animate class
%
%% Description
%
%% Implementation
%
classdef Animate < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        title    string  = string.empty;    % animation title
        res_type uint8   = uint8.empty;     % flag for type of result
        pids     logical = logical.empty;   % flag for ploting particles IDs
    end
    
    %% Constructor method
    methods
        function this = Animate()
            this.setDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.pids = false;
        end
        
        %------------------------------------------------------------------
        function execute(this,drv)
            
        end
    end
end