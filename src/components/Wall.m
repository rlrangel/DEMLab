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
        fc_velocity    Cond = Cond.empty;
        fc_temperature Cond = Cond.empty;
        
        % Flags for free/fixed particles
        free_mech  logical = logical.empty;   % flag for mechanically free particle
        free_therm logical = logical.empty;   % flag for thermally free particle
        
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
        setFCVelocity(this,time,dt);
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setFreeMech(this,time)
            if (isempty(this.fc_velocity))
                this.free_mech = true;
            else
                for i = 1:length(this.fc_velocity)
                    if (this.fc_velocity(i).isActive(time))
                        this.free_mech = false;
                        return;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function setFreeTherm(this,time)
            if (isempty(this.fc_temperature))
                this.free_therm = true;
            else
                for i = 1:length(this.fc_temperature)
                    if (this.fc_temperature(i).isActive(time))
                        this.free_therm = false;
                        return;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function setFCTemperature(this,time)
            if (this.free_therm)
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