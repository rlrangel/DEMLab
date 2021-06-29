%% Interact class
%
%% Description
%
%% Implementation
%
classdef Interact < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Members
        element1;   % object of the first interaction element (defines the sign convection)
        element2;   % object of the second interaction element
        
        % Interaction models
        contact_kinematics    ContactKinematics   = ContactKinematics.empty;
        contact_force_normal  ContactForceNormal  = ContactForceNormal.empty;
        contact_force_tangent ContactForceTangent = ContactForceTangent.empty;
        contact_conduction    ContactConduction   = ContactConduction.empty;
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
