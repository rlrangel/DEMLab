%% Condition_Oscillatory class
%
%% Description
%
% This is a sub-class of the <Condition.html Condition> class for the
% implementation of *Oscillatory* conditions.
%
% In a given time _t_, an oscillatory condition value _y_ is obtained as:
%
% $$y(t) = y_{0} + \lambda sin \left (  \frac{2pi}{\tau}(t-t_{0}) + \phi \right )$$
%
% Where:
%
% $t_{0}$: Initial time (when condition is activated)
%
% $y_{0}$: Base value for oscillation
%
% $\lambda$: Oscillation amplitude around base value
%
% $\tau$: Oscillation period
%
% $\phi$: Oscillation phase shift
%
classdef Condition_Oscillatory < Condition
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        base_value double = double.empty;   % base condition value for oscillation
        amplitude  double = double.empty;   % amplitude of oscillation around base value
        period     double = double.empty;   % period of oscillation
        shift      double = double.empty;   % shift from initial point of oscillation (phase angle)
    end
    
    %% Constructor method
    methods
        function this = Condition_Oscillatory()
            this = this@Condition(Condition.OSCILLATORY);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.base_value = 0;
            this.amplitude  = 0;
            this.period     = inf;
            this.shift      = 0;
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            val = this.base_value + this.amplitude * sin(2*pi*(time-this.init_time)/this.period + this.shift);
        end
    end
end