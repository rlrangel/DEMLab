%% AreaCorrect (Area Correction) class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of models
% for the correction of the contact area, or radius, between elements.
%
% The correction of the contact area is necessary when a low value of the
% Young modulus, compared to the real one, is used for particles.
% The modified Young modulus leads to a larger contact area, which have
% some side effects, such as the increase of direct heat conduction.
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <areacorrect_zyz.html AreaCorrect_ZYZ> (default)
% * <areacorrect_lmlb.html AreaCorrect_LMLB>
% * <areacorrect_mpmh.html AreaCorrect_MPMH>
%
classdef AreaCorrect < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of model
        ZYZ  = uint8(1);
        LMLB = uint8(2);
        MPMH = uint8(3);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of model
    end
    
    %% Constructor method
    methods
        function this = AreaCorrect(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = AreaCorrect_ZYZ;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        this = fixRadius(this,interact);
    end
end