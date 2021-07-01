%% Material class
%
%% Description
%
%% Implementation
%
classdef Material < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Indentification
        name string = string.empty;   % identification name of model part
        
        % Mechanical properties
        density     double = double.empty;
        young       double = double.empty;
        young_real  double = double.empty;
        shear       double = double.empty;
        poisson     double = double.empty;
        restitution double = double.empty;
        
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
    
    %% Public methods
    methods
        
    end
end