%% BBox_Rectangle class
%
%% Description
%
%% Implementation
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
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function do = removeParticle(this,particle,time)
            if (time < min(this.interval) || time > max(this.interval))
                do = false;
                return;
            end
            if (any(particle.coord < this.limit_min) ||...
                any(particle.coord > this.limit_max))
                do = true;
            else
                do = false;
            end
        end
    end
end