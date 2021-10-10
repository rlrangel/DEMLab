%% Print class
%
%% Description
%
% This is a handle super-class responsible for printing output files with
% the required results.
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <print_pos.html Print_Pos>
%
classdef Print < handle
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
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        execute(this,drv);
    end
end