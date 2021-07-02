%% BinKinematics (Binary Kinematics) class
%
%% Description
%
%% Subclasses
%
%% Implementation
%
classdef BinKinematics < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of binary kinematics
        PARTICLE_PARTICLE    = uint8(1);
        PARTICLE_WALL_LINE   = uint8(2);
        PARTICLE_WALL_CIRCLE = uint8(3);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type int8 = uint8.empty; % flag for type of binary kinematics
        
        % Unit direction vectors (normal and tangential)
        dir_n double = double.empty;
        dir_t double = double.empty;
        
        % Overlaps (normal and tangential)
        ovlp_n double = double.empty;
        ovlp_t double = double.empty;
        
        % Overlap rates of change (normal and tangential)
        vel_n double = double.empty;
        vel_t double = double.empty;
    end
    
    %% Constructor method
    methods
        function this = BinKinematics()
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = BinKinematics_PP;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        setEffParams(this,interact);
        
        %------------------------------------------------------------------
        [d,n] = distBtwSurf(this,e1,e2);
        
        %------------------------------------------------------------------
        evalRelPosVel(this,interact,time_step);
    end
    
    %% Public methods
    methods
        
    end
end