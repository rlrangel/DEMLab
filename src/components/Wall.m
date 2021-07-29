%% Wall class
%
%% Description
%
%% Subclasses
%
%% Implementation
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
        
        % Neighbours Interactions
        interacts Interact = Interact.empty;    % handles to objects of Interact class
        
        % Fixed conditions (handles to objects of Cond class)
        fc_translation Cond = Cond.empty;
        fc_rotation    Cond = Cond.empty;
        fc_temperature Cond = Cond.empty;
        
        % Flags for free/fixed wall
        fixed_motion logical = logical.empty;   % flag for fixed motion wall
        fixed_therm  logical = logical.empty;   % flag for fixed temperature wall
        
        % Current mechanical state
        veloc_trl double = double.empty;   % translational velocity
        veloc_rot double = double.empty;   % rotational velocity
        
        % Current thermal state
        temperature double = double.empty;   % temperature
    end
    
    %% Constructor method
    methods
        function this = Wall(type)
            if (nargin > 0)
                this.type = type;
            end
        end
    end
    
    %% Default subclass definition
    methods (Static, Access = protected)
        function defaultObject = getDefaultScalarElement
            defaultObject = Wall_Line;
        end
    end
    
    %% Abstract methods
    methods (Abstract)
        %------------------------------------------------------------------
        setDefaultProps(this);
        
        %------------------------------------------------------------------
        setFCMotion(this,time,dt);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setFreeMotion(this,time)
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
        function setFreeTherm(this,time)
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