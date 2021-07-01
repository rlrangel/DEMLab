%% Interact class
%
%% Description
%
%% Implementation
%
classdef Interact < handle & matlab.mixin.Copyable
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Members
        elem1;   % object of the first interaction element (defines the sign convection)
        elem2;   % object of the second interaction element
        
        % Effective contact parameters
        eff_radius double = double.empty;
        eff_mass   double = double.empty;
        eff_young  double = double.empty;
        
        % Interaction models
        contact_kinematics    ContactKinematics = ContactKinematics.empty;
        contact_force_normal  ContactForceN     = ContactForceN.empty;
        contact_force_tangent ContactForceT     = ContactForceT.empty;
        contact_conduction    ContactConduction = ContactConduction.empty;
    end
    
    %% Constructor method
    methods
        function this = Interact()
            
        end
    end
    
    %% Public methods
    methods
        
    end
end
