%% Wall_Line class
%
%% Description
%
%% Implementation
%
classdef Wall_Line < Wall
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Position
        coord_ini double = double.empty;   % coordinates of initial point
        coord_end double = double.empty;   % coordinates of final point
        
        % Geometric properties
        len double = double.empty;   % length of line
    end
    
    %% Constructor method
    methods
        function this = Wall_Line()
            this = this@Wall(Wall.LINE);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            % Thermal state variables
            this.temperature = 0;
        end
    end
end