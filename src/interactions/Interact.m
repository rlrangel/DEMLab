%% Interact class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of binary
% interactions between elements (particle-particle and particle-wall).
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
        
        % Interaction models (value class objects)
        kinemat BinKinematics     = BinKinematics.empty;       % general binary kinematics
        cforcen ContactForceN     = ContactForceN.empty;       % contact force normal
        cforcet ContactForceT     = ContactForceT.empty;       % contact force tangent
        cconduc ContactConduction = ContactConduction.empty;   % contact thermal conduction
    end
    
    %% Constructor method
    methods
        function this = Interact()
            
        end
    end
end
