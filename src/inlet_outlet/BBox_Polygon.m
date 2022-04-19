%% BBox_Polygon class
%
%% Description
%
% This is a sub-class of the <BBox.html BBox> class for the implementation
% of *Polygon* bounding boxes.
%
classdef BBox_Polygon < BBox
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        coord_x double = double.empty;   % vector of X coodinates of polygon points
        coord_y double = double.empty;   % vector of Y coodinates of polygon points
    end
    
    %% Constructor method
    methods
        function this = BBox_Polygon()
            this = this@BBox(BBox.POLYGON);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.coord_x = [-inf,inf,inf,-inf];
            this.coord_y = [-inf,-inf,inf,inf];
            warning('off','MATLAB:inpolygon:ModelingWorldUpper');
        end
        
        %------------------------------------------------------------------
        function do = removeParticle(this,p,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            try
                do = ~(inpolygon(p.coord(1),p.coord(2),this.coord_x,this.coord_y));
            catch
                do = false;
            end
        end
    end
end