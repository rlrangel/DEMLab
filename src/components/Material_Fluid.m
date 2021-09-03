%% Material_Fluid class
%
%% Description
%
% This is a sub-class of the <material.html Material> class for the
% implementation of *Fluid* materials.
%
% A single fluid material can be assigned to the model in order to set the
% global properties for the interstitial fluid between particles.
%
classdef Material_Fluid < Material
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Fluid properties
        Pr        double = double.empty;   % Prandtl number
        viscosity double = double.empty;   % dynamic viscosity
    end
    
    %% Constructor method
    methods
        function this = Material_Fluid()
            this = this@Material(Material.FLUID);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(~)
            
        end
    end
    
    %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function setPrandtl(this)
            if (~isempty(this.viscosity) && ~isempty(this.hcapacity) && ~isempty(this.conduct))
                this.Pr = this.viscosity * this.hcapacity / this.conduct;
            end
        end
    end
end