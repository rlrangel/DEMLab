%% PC_Linear class
%
%% Description
%
%% Implementation
%
classdef PC_Linear < PC
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        init_value double = double.empty;   % initial value of prescribed condition when activated
        slope      double = double.empty;   % rate of change of prescribed condition value
    end
    
    %% Constructor method
    methods
        function this = PC_Linear()
            this = this@PC(PC.LINEAR);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.init_value = 0;
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            min_time = min(this.interval);
            if (min_time < 0)
                min_time = 0;
            end
            val = deal(this.init_value) + this.slope * (time-min_time);
        end
    end
end