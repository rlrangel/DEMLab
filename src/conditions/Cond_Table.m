%% Cond_Table class
%
%% Description
%
%% Implementation
%
classdef Cond_Table < Cond
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        val_x  double = double.empty;   % independente variable (time) values
        val_y  double = double.empty;   % condition values
        interp uint8  = uint8.empty;    % flag for interpolation method
    end
    
    %% Constructor method
    methods
        function this = Cond_Table()
            this = this@Cond(Cond.TABLE);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
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