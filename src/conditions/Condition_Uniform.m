%% Condition_Uniform class
%
%% Description
%
% This is a sub-class of the <Condition.html Condition> class for the
% implementation of *Uniform* conditions.
%
% In a given time _t_, a uniform condition value _y_, is obtained as:
%
% $y(t) = y_{0}$, for all _t_
%
% Where:
%
% $y_{0}$: Uniform value
%
%% Implementation
%
classdef Condition_Uniform < Condition
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        value double = double.empty;   % uniform condition value
    end
    
    %% Constructor method
    methods
        function this = Condition_Uniform()
            this = this@Condition(Condition.UNIFORM);
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