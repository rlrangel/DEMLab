%% BBox_Circle class
%
%% Description
%
% This is a sub-class of the <bbox.html BBox> class for the implementation
% of *Circle* bounding boxes.
%
classdef BBox_Circle < BBox
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        center double = double.empty;   % coordinates of center point
        radius double = double.empty;   % radius
    end
    
    %% Constructor method
    methods
        function this = BBox_Circle()
            this = this@BBox(BBox.CIRCLE);
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.center = [0,0];
            this.radius = inf;
        end
        
        %------------------------------------------------------------------
        function do = removeParticle(this,p,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            do = (norm(p.coord-this.center) > this.radius);
        end
    end
end