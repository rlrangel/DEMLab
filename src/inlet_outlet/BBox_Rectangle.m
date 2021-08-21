%% BBox_Rectangle class
%
%% Description
%
% This is a sub-class of the <bbox.html BBox> class for the implementation
% of *Rectangle* bounding boxes.
%
classdef BBox_Rectangle < BBox
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        limit_min double = double.empty;   % coordinates of minimum limits (bottom-left corner)
        limit_max double = double.empty;   % coordinates of maximum limits (top-right corner)
    end
    
    %% Constructor method
    methods
        function this = BBox_Rectangle()
            this = this@BBox(BBox.RECTANGLE);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.limit_min = [-inf,-inf];
            this.limit_max = [inf,inf];
        end
        
        %------------------------------------------------------------------
        function do = removeParticle(this,p,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            do = (any(p.coord < this.limit_min) || any(p.coord > this.limit_max));
        end
    end
end