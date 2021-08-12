%% ConductionIndirect (Indirect Heat Conduction) class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of models
% for the indirect heat conduction between elements.
%
% Indirect heat conduction happens through the thin wedge of interstitial 
% fluid in-between elements, which can be touching each other or not.
%
% In the figure below, _Qpfp_ is the indirect condution (_pfp_ stands for
% particle-fluid-particle) and _Qcpp_ is the 
% <conductiondirect.html direct conduction> (_cpp_ stands for contact
% particle-particle). The total heat conduction between elements is the sum
% of both contributions.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <conductionindirect_voronoia.html ConductionIndirect_VoronoiA> (default)
%
% <<indirect_conduction.png>>
%
classdef ConductionIndirect < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        VORONOI_A = uint8(1);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of model
        
        % Heat rate results
        total_hrate double = double.empty;   % resulting heat rate
    end
    
    %% Constructor method
    methods
        function this = ConductionIndirect(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ConductionIndirect_VoronoiA;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        this = setDefaultProps(this);
        
        %------------------------------------------------------------------
        this = setCteParams(this,interact);
        
        %------------------------------------------------------------------
        this = evalHeatRate(this,interact);
    end
end