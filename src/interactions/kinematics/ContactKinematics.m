%% ContactKinematics class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef ContactKinematics < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of contact kinematics
        PARTICLE_PARTICLE = uint8(1);
        PARTICLE_WALL     = uint8(2);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type int8 = uint8.empty; % flag for type of contact kinematics
        
        % Distances
        ovlp_norm double = double.empty;   % normal overlap (distance between surface of elements)
        ovlp_tang double = double.empty;   % tangential overlap
        
        % Unit direction vectors
        dir_n double = double.empty;   % normal direction
        dir_t double = double.empty;   % tangential direction
        
        % Velocities
    end
    
    %% Constructor method
    methods
        function this = ContactKinematics()
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = ContactKinematics_PP;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        setEffParams(this,interact);
        
        %------------------------------------------------------------------
        evalRelPosVel(this,interact);
    end
    
    %% Public methods
    methods
        
    end
end