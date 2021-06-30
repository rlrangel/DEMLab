%% PC_Oscilatory class
%
%% Description
%
%% Implementation
%
classdef PC_Oscilatory < PC
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        init_value double = double.empty;   % initial value of prescribed condition
        amplitude  double = double.empty;   % value amplitude
        phase      double = double.empty;   % 
        period     double = double.empty;   % 
    end
    
    %% Constructor method
    methods
        function this = PC_Oscilatory(condition)
            this = this@PC(PC.OSCILLATORY,condition);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.phase = 0;
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            
        end
    end
end