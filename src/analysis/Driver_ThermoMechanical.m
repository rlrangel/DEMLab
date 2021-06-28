%% Driver_ThermoMechanical class
%
%% Description
%
%% Implementation
%
classdef Driver_ThermoMechanical < Driver
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Global conditions
        gravity double = double.empty;   % vector of gravity value components
        
        % Time integration
        scheme_vtrl Scheme = Scheme.empty;   % object of the Scheme class for translational velocity
        scheme_vrot Scheme = Scheme.empty;   % object of the Scheme class for rotational velocity
        scheme_temp Scheme = Scheme.empty;   % object of the Scheme class for temperature
    end
    
    %% Constructor method
    methods
        function this = Driver_ThermoMechanical()
            this = this@Driver(Driver.THERMO_MECHANICAL);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.n_mparts    = 0;
            this.n_particles = 0;
            this.n_walls     = 0;
            this.n_materials = 0;
            this.scheme_vtrl = Scheme_FowardEuler();
            this.scheme_vrot = Scheme_FowardEuler();
            this.scheme_temp = Scheme_FowardEuler();
            this.parallel    = any(any(contains(struct2cell(ver),'Parallel Computing Toolbox')));
            this.workers     = parcluster('local').NumWorkers;
            this.auto_step   = true;
        end
    end
end