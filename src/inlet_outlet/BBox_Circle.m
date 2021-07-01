%% BBox_Circle class
%
%% Description
%
%% Implementation
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
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function do = removeParticle(this,particle,time)
            if (~this.isActive(time))
                do = false;
                return;
            end
            do = (norm(particle.coord-this.center) > this.radius);
        end
    end
end