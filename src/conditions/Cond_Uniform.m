%% Cond_Uniform class
%
%% Description
%
%% Implementation
%
classdef Cond_Uniform < Cond
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        value double = double.empty;   % uniform condition value
    end
    
    %% Constructor method
    methods
        function this = Cond_Uniform()
            this = this@Cond(Cond.UNIFORM);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
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