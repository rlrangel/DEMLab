%% Wall class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of rigid
% walls.
%
% Rigid walls are not solved with mechanical and / or thermal equilibrium
% equations.
% Their motion and / or temperature are not influenced by their
% interactions with other elements.
%
% A wall may or may not have an assigned material.
% If it does, the effective interaction properties take into account the
% material properties from both the wall and the particle.
% Otherwise, the effective interaction properties for the mechanical
% behavior are set as the particle material, and the wall is considered as
% adiabatic (no heat exchange with particles).
%
% This super-class defines abstracts methods that must be implemented in
% the derived *sub-classes*:
%
% * <wall_line.html Wall_Line> (default)
% * <wall_circle.html Wall_Circle>
%
classdef Wall < handle & matlab.mixin.Heterogeneous
    %% Constant values
    properties (Constant = true, Access = public)
        % Types of wall
        LINE   = uint8(1);
        CIRCLE = uint8(2);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type uint8  = uint8.empty;    % flag for type of wall
        id   uint32 = uint32.empty;   % identification number
        
        % Physical properties
        material Material = Material.empty;   % handle to object of Material class
        
        % Behavior flags
        fixed_motion logical = logical.empty;   % flag for fixed motion wall
        fixed_therm  logical = logical.empty;   % flag for fixed temperature wall
        adiabatic    logical = logical.empty;   % flag for adiabatic wall (no heat transfer with particles)
        
        % Fixed conditions (handles to objects of Condition class)
        fc_translation Condition = Condition.empty;
        fc_rotation    Condition = Condition.empty;
        fc_temperature Condition = Condition.empty;
        
        % Current mechanical state
        veloc_trl double = double.empty;   % translational velocity
        veloc_rot double = double.empty;   % rotational velocity
        
        % Current thermal state
        temperature double = double.empty;
    end
    
    %% Constructor method
    methods
        function this = Wall(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default sub-class definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Wall_Line;
        end
    end
    
    %% Abstract methods: implemented in derived sub-classes
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        setFCMotion(this,time,dt);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setFixedMotion(this,time)
            if (isempty(this.fc_translation) && isempty(this.fc_rotation))
                this.fixed_motion = false;
            else
                for i = 1:length(this.fc_translation)
                    if (this.fc_translation(i).isActive(time))
                        this.fixed_motion = true;
                        return;
                    end
                end
                for i = 1:length(this.fc_rotation)
                    if (this.fc_rotation(i).isActive(time))
                        this.fixed_motion = true;
                        return;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function setFixedThermal(this,time)
            if (isempty(this.fc_temperature))
                this.fixed_therm = false;
            else
                for i = 1:length(this.fc_temperature)
                    if (this.fc_temperature(i).isActive(time))
                        this.fixed_therm = true;
                        return;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function setFCTemperature(this,time)
            if (~this.fixed_therm)
                return;
            end
            for i = 1:length(this.fc_temperature)
                if (this.fc_temperature(i).isActive(time))
                    this.temperature = this.fc_temperature(i).getValue(time);
                end
            end
        end
    end
end