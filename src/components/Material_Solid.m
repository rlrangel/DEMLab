%% Material_Solid class
%
%% Description
%
% This is a sub-class of the <Material.html Material> class for the
% implementation of *Solid* materials.
%
% Solid materials must be assigned to all particles and can be assigned to
% walls in order to account for their properties during particle-wall
% interactions.
%
classdef Material_Solid < Material
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Solid properties
        young   double = double.empty;   % Young modulus (used in simulation)
        young0  double = double.empty;   % Young modulus (real physical value)
        shear   double = double.empty;   % shear modulus
        poisson double = double.empty;   % Poisson ratio
    end
    
    %% Constructor method
    methods
        function this = Material_Solid()
            this = this@Material(Material.SOLID);
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
        function s = getShear(this)
            if (~isempty(this.young) && ~isempty(this.poisson))
                s = this.young / (2 + 2 * this.poisson);
            else
                s = 0;
            end
        end
    end
end