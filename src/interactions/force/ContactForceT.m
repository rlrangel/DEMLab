%% ContactForceT (Tangent Contact Force) class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of models
% for the tangent contact force between elements.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <contactforcet_spring.html ContactForceT_Spring> (default)
% * <contactforcet_dashpot.html ContactForceT_Dashpot>
% * <contactforcet_slider.html ContactForceT_Slider>
% * <contactforcet_springslider.html ContactForceT_SpringSlider>
% * <contactforcet_dashpotslider.html ContactForceT_DashpotSlider>
% * <contactforcet_sdslinear.html ContactForceT_SDSLinear>
% * <contactforcet_sdsnonlinear.html ContactForceT_SDSNonlinear>
%
classdef ContactForceT < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        SLIDER         = uint8(1);
        SPRING         = uint8(2);
        DASHPOT        = uint8(3);
        SPRING_SLIDER  = uint8(4);
        DASHPOT_SLIDER = uint8(5);
        SDS_LINEAR     = uint8(6);
        SDS_NONLINEAR  = uint8(7);
        
        % Types of nonlinear SDS formulation
        DD  = uint8(1);
        LTH = uint8(2);
        ZZY = uint8(3);
        TTI = uint8(4);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of model
        
        % Contact parameters
        restitution double = double.empty;   % tangent coefficient of restitution
        
        % Force results
        total_force double = double.empty;   % resulting force vector
    end
    
    %% Constructor method
    methods
        function this = ContactForceT(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactForceT_Spring;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        this = setDefaultProps(this);
        
        %------------------------------------------------------------------
        this = setCteParams(this,interact);
        
        %------------------------------------------------------------------
        this = evalForce(this,interact);
    end
end