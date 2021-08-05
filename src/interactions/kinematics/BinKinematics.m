%% BinKinematics (Binary Kinematics) class
%
%% Description
%
% This is a value heterogeneous super-class for the definition of the
% kinematics for binary interactions between elements.
%
% It deals with the calculation of distances, relative positions and
% velocities, and contact geometry.
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <binkinematics_spheresphere.html BinKinematics_SphereSphere> (default)
% * <binkinematics_spherewlin.html BinKinematics_SphereWlin>
% * <binkinematics_spherewcirc.html BinKinematics_SphereWcirc>
% * <binkinematics_cylindercylinder.html BinKinematics_CylinderCylinder>
% * <binkinematics_cylinderwlin.html BinKinematics_CylinderWlin>
% * <binkinematics_cylinderwcirc.html BinKinematics_CylinderWcirc>
%
classdef BinKinematics < matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of binary kinematics between same particles
        SPHERE_SPHERE     = uint8(1);
        CYLINDER_CYLINDER = uint8(2);
        
        % Types of binary kinematics between particles and walls
        SPHERE_WALL_LINE     = uint8(3);
        SPHERE_WALL_CIRCLE   = uint8(4);
        CYLINDER_WALL_LINE   = uint8(5);
        CYLINDER_WALL_CIRCLE = uint8(6);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8 = uint8.empty;   % flag for type of binary kinematics
        
        % Relative position
        dir   double = double.empty;   % direction between centroids
        dist  double = double.empty;   % distance between centroids
        separ double = double.empty;   % separation between surfaces
        
        % Normal overlap parameters
        dir_n  double = double.empty;   % unit direction vector
        ovlp_n double = double.empty;   % overlap
        vel_n  double = double.empty;   % overlap rate of change
        
        % Tangent overlap parameters
        dir_t  double = double.empty;   % unit direction vector
        ovlp_t double = double.empty;   % overlap
        vel_t  double = double.empty;   % overlap rate of change
        
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
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = BinKinematics_SphereSphere;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
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