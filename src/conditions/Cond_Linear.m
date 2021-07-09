%% Cond_Linear class
%
%% Description
%
%% Implementation
%
classdef Cond_Linear < Cond
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        init_value double = double.empty;   % initial condition value when activated
        slope      double = double.empty;   % rate of change of prescribed condition value
    end
    
    %% Constructor method
    methods
        function this = Cond_Linear()
            this = this@Cond(Cond.LINEAR);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.init_value = 0;
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            val = deal(this.init_value) + this.slope * (time-this.init_time);
        end
    end
end