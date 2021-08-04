%% Material class
%
%% Description
%
% This is a handle class for the definition of materials.
%
% It stores mechanical and / or thermal material properties related to
% solids.
%
classdef Material < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Indentification
        name string = string.empty;
        
        % Mechanical properties
        density    double = double.empty;
        young      double = double.empty;
        young_real double = double.empty;
        shear      double = double.empty;
        poisson    double = double.empty;
        
        % Thermal properties
        conduct   double = double.empty;
        hcapacity double = double.empty;
        expansion double = double.empty;
    end
    
    %% Constructor method
    methods
        function this = Material()
            
        end
    end
end