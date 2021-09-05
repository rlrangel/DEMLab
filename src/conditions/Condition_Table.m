%% Condition_Table class
%
%% Description
%
% This is a sub-class of the <Condition.html Condition> class for the
% implementation of *Table* conditions.
%
% Different methods can be used for interpolating the table values:
%
% * Linear
% * Makima
% * Pchip
% * Spline
%
% For more information on these methods, check their description
% <https://www.mathworks.com/help/matlab/ref/interp1.html#btwp6lt-1-method here>
%
classdef Condition_Table < Condition
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        val_x  double = double.empty;   % independente variable (time) values
        val_y  double = double.empty;   % condition values
        interp uint8  = uint8.empty;    % flag for interpolation method
    end
    
    %% Constructor method
    methods
        function this = Condition_Table()
            this = this@Condition(Condition.TABLE);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.interp = this.INTERP_LINEAR;
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            switch this.interp
                case this.INTERP_LINEAR
                    val = interp1(this.val_x,this.val_y,time,'linear');
                case this.INTERP_MAKIMA
                    val = interp1(this.val_x,this.val_y,time,'makima');
                case this.INTERP_PCHIP
                    val = interp1(this.val_x,this.val_y,time,'pchip');
                case this.INTERP_SPLINE
                    val = interp1(this.val_x,this.val_y,time,'spline');
            end
        end
    end
end