%% Print class
%
%% Description
%
% This is a handle heterogeneous super-class responsible for printing
% output files with the required results.
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <Print_Pos.html Print_Pos> (default)
%
classdef Print < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of output formats
        POS = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        type uint8 = uint8.empty;   % flag for type of output format
    end
    
    %% Constructor method
    methods
        function this = Print(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Print_Pos;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        execute(this,drv);
    end
end