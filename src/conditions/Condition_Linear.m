%% Condition_Linear class
%
%% Description
%
% This is a sub-class of the <Condition.html Condition> class for the
% implementation of *Linear* conditions.
%
% In a given time _t_, a linear condition value _y_, is obtained as:
%
% $$y(t) = y_{0} + s \times (t-t_{0})$$
%
% Where:
%
% $t_{0}$: Initial time (when condition is activated)
%
% $y_{0}$: Value at initial time
%
% $s$: Time rate of change
%
classdef Condition_Linear < Condition
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        init_value double = double.empty;   % initial condition value when activated
        slope      double = double.empty;   % rate of change of prescribed condition value
    end
    
    %% Constructor method
    methods
        function this = Condition_Linear()
            this = this@Condition(Condition.LINEAR);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
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