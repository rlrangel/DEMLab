%% PC_Uniform class
%
%% Description
%
%% Implementation
%
classdef PC_Uniform < PC
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        value double = double.empty;   % uniform value of prescribed condition
    end
    
    %% Constructor method
    methods
        function this = PC_Uniform()
            this = this@PC(PC.UNIFORM);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(~)
            
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,~)
            val = this.value;
        end
    end
end