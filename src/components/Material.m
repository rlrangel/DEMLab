%% Material class
%
%% Description
%
% This is a handle super-class for the definition of materials.
%
% This super-class defines generic properties for all material types,
% while specific properties are defined in the derived *sub-classes*:
%
% * <material_solid.html Material_Solid>
% * <material_fluid.html Material_Fluid>
%
classdef Material < handle
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of material
        SOLID = uint8(1);
        FLUID = uint8(2);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Indentification
        type uint8  = uint8.empty;    % flag for type of material
        name string = string.empty;   % identification name of material
        
        % Generic properties
        density   double = double.empty;   % density
        conduct   double = double.empty;   % thermal conductivity
        hcapacity double = double.empty;   % heat capacity
    end
    
    %% Constructor method
    methods
        function this = Material(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
    end
end