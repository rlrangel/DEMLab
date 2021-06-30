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
        function this = PC_Linear(condition)
            this = this@PC(PC.LINEAR,condition);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            if (this.condition == this.FORCE)
                this.init_value = [0,0];
            elseif (this.condition == this.TORQUE    ||...
                    this.condition == this.HEAT_FLUX ||...
                    this.condition == this.HEAT_RATE)
                this.init_value = 0;
            end
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            val = this.init_value + this.slope * time;
        end
    end
end