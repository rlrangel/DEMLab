%% Condition_Constant class
%
%% Description
%
% This is a sub-class of the <Condition.html Condition> class for the
% implementation of *Constant* conditions.
%
% In a given time _t_, a constant condition value _y_, is obtained as:
%
% $y(t) = y_{0}$, for all _t_
%
% Where:
%
% $y_{0}$: Constant value
%
%% Implementation
%
classdef Condition_Constant < Condition
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        value double = double.empty;   % constant condition value
    end
    
    %% Constructor method
    methods
        function this = Condition_Constant()
            this = this@Condition(Condition.CONSTANT);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(~)
            
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,~)
            val = this.value;
        end
    end
end