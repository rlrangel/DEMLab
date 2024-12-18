%% Search class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of search
% algorithms.
%
% A search algorithm is invoked frequently during the simulation to
% identify the neighbours of each particle.
%
% Depending on the interaction models adopted, a cutoff distance is
% assumed for defining a neighbour (contact neighbours have a cutoff
% distance of zero).
%
% This super-class defines abstract methods that must be implemented in
% the derived *sub-classes*:
%
% * <Search_SimpleLoop.html Search_SimpleLoop> (default)
% * <Search_VerletList.html Search_VerletList>
%
classdef Search < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of search algorithm
        SIMPLE_LOOP = uint8(1);
        VERLET_LIST = uint8(2);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8   = uint8.empty;     % flag for type of search algorithm
        done logical = logical.empty;   % flag for identifying if search has been done in current time step
        
        % Parameters
        freq   uint32 = uint32.empty;   % search frequency (in steps)
        cutoff double = double.empty;   % cut-off neighbour distance (radius multiplication factor)
        
        % Base object for common interactions
        b_interact Interact = Interact.empty;   % handle to object of Interact class for all interactions
    end
    
    %% Constructor method
    methods
        function this = Search(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Search_SimpleLopp;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        initialize(this,drv);
        
        %------------------------------------------------------------------
        execute(this,drv);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function kin = createPPKinematic(~,p1,dir,dist,separ)
            % Only sphere-sphere or cylinder-cylinder interactions
            switch p1.type
                case p1.SPHERE
                    kin = BinKinematics_SphereSphere(dir,dist,separ);
                case p1.CYLINDER
                    kin = BinKinematics_CylinderCylinder(dir,dist,separ);
            end
        end
        
        %------------------------------------------------------------------
        function type = pwInteractionType(~,p,w)
            switch p.type
                case p.SPHERE
                    switch w.type
                        case w.LINE
                            type = 1;
                        case w.CIRCLE
                            type = 2;
                    end
                case p.CYLINDER
                    switch w.type
                        case w.LINE
                            type = 3;
                        case w.CIRCLE
                            type = 4;
                    end
            end
        end
    end
end