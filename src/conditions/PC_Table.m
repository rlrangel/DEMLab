%% PC_Table class
%
%% Description
%
%% Implementation
%
classdef PC_Table < PC
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        val_x  double = double.empty;   % independente variable (time) values
        val_y  double = double.empty;   % prescribed condition values
        method uint8  = uint8.empty;    % flag for interpolation method
    end
    
    %% Constructor method
    methods
        function this = PC_Table(condition)
            this = this@PC(PC.TABLE,condition);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.method = this.INTERP_LINEAR;
        end
        
        %------------------------------------------------------------------
        function val = getValue(this,time)
            switch this.method
                case this.INTERP_LINEAR
                    val = interp1(this.val_x,this.val_y,time,'linear');
                case this.INTERP_MAKIMA
                    val = interp1(this.val_x,this.val_y,time,'makima');
                case this.INTERP_CUBIC
                    val = interp1(this.val_x,this.val_y,time,'cubic');
                case this.INTERP_PCHIP
                    val = interp1(this.val_x,this.val_y,time,'pchip');
                case this.INTERP_SPLINE
                    val = interp1(this.val_x,this.val_y,time,'spline');
            end
        end
    end
end