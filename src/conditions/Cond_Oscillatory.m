%% Cond_Oscillatory class
%
%% Description
%
%% Implementation
%
classdef Cond_Oscillatory < Cond
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        base_value double = double.empty;   % base condition value for oscillation
        amplitude  double = double.empty;   % amplitude of oscillation around base value
        period     double = double.empty;   % period of oscillation
        shift      double = double.empty;   % shift from initial point of oscillation (phase angle)
    end
    
    %% Constructor method
    methods
        function this = Cond_Oscillatory()
            this = this@Cond(Cond.OSCILLATORY);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.shift = 0;
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            val = this.base_value + this.amplitude * sin(2*pi*(time-this.init_time)/this.period + this.shift);
        end
    end
end