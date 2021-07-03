%% PC_Oscillatory class
%
%% Description
%
%% Implementation
%
classdef PC_Oscillatory < PC
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        base_value double = double.empty;   % base value of prescribed condition for oscillation
        amplitude  double = double.empty;   % amplitude of oscillation around base value
        period     double = double.empty;   % period of oscillation
        shift      double = double.empty;   % shift from initial point of oscillation (phase angle)
    end
    
    %% Constructor method
    methods
        function this = PC_Oscillatory()
            this = this@PC(PC.OSCILLATORY);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.shift = 0;
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            val = this.base_value + this.amplitude * sin(2*pi*(time-this.init_time)/this.period + this.shift);
        end
    end
end