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
        type int8 = uint8.empty;   % flag for type of binary kinematics
        
        % Relative position
        dir   double = double.empty;   % direction between centroids
        dist  double = double.empty;   % distance between centroids
        separ double = double.empty;   % separation between surfaces
        
        % Overlap parameters
        dir_n      double  = double.empty;    % unit direction vector (normal)
        dir_t      double  = double.empty;    % unit direction vector (tangent)
        ovlp_n     double  = double.empty;    % overlap (normal)
        ovlp_t     double  = double.empty;    % overlap (tangent)
        vel_n      double  = double.empty;    % overlap rate of change (normal)
        vel_t      double  = double.empty;    % overlap rate of change (tangent)
        
        % Contact parameters
        is_contact     logical = logical.empty;   % flag for contact interaction
        v0_n           double  = double.empty;    % initial (impact) normal velocity
        contact_start  double  = double.empty;    % starting time
        contact_time   double  = double.empty;    % duration since starting time
        contact_radius double  = double.empty;    % contact radius
        contact_area   double  = double.empty;    % contact area
    end
    
    %% Constructor method
    methods
        function this = BinKinematics(type)
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
        this = setRelPos(this,element1,element2);
        
        %------------------------------------------------------------------
        this = setOverlaps(this,interact,time_step);
        
        %------------------------------------------------------------------
        this = setContactArea(this,interact);
        
        %------------------------------------------------------------------
        addContactForceToParticles(this,interact);
        
        %------------------------------------------------------------------
        addContactTorqueToParticles(this,interact);
        
        %------------------------------------------------------------------
        addContactConductionToParticles(this,interact);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function this = setCollisionParams(this,time)
            this.is_contact    = true;
            this.contact_start = time;
            this.v0_n          = this.vel_n;
        end
        
        %------------------------------------------------------------------
        function this = setEndParams(this)
            this.is_contact = false;
            this.ovlp_t     = 0;
        end
    end
end