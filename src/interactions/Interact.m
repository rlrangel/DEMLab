%% Interact class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of binary
% interactions between elements (particle-particle and particle-wall).
%
% It stores the effective properties of the interaction and contains
% handles to specific interaction models for kinematics, force and heat
% transfer.
%
classdef Interact < handle & matlab.mixin.Copyable
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Members
        elem1;   % handle to object of the 1st interaction element (defines the sign convection)
        elem2;   % handle to object of the 2nd interaction element
        
        % Effective contact parameters
        eff_radius  double = double.empty;
        eff_mass    double = double.empty;
        eff_young   double = double.empty;
        eff_shear   double = double.empty;
        eff_poisson double = double.empty;
        eff_conduct double = double.empty;
        
        % Mechanical interaction models (value class objects)
        kinemat BinKinematics = BinKinematics.empty;   % general binary kinematics
        cforcen ContactForceN = ContactForceN.empty;   % contact force normal
        cforcet ContactForceT = ContactForceT.empty;   % contact force tangent
        rollres RollResist    = RollResist.empty;      % rolling resistance
        
        % Thermal interaction models (value class objects)
        cconduc ContactConduction = ContactConduction.empty;   % contact thermal conduction
    end
    
    %% Constructor method
    methods
        function this = Interact()
            
        end
    end
end
