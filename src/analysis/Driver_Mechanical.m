%% Driver_Mechanical class
%
%% Description
%
%% Implementation
%
classdef Driver_Mechanical < Driver
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Global conditions
        gravity double = double.empty;   % vector of gravity value components
        
        % Time integration
        scheme_vtrl Scheme = Scheme.empty;   % object of the Scheme class for translational velocity
        scheme_vrot Scheme = Scheme.empty;   % object of the Scheme class for rotational velocity
    end
    
    %% Constructor method
    methods
        function this = Driver_Mechanical()
            this = this@Driver(Driver.MECHANICAL);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.n_mparts    = 0;
            this.n_particles = 0;
            this.n_walls     = 0;
            this.n_interacts = 0;
            this.n_materials = 0;
            this.n_prescond  = 0;
            this.scheme_vtrl = Scheme_FowardEuler();
            this.scheme_vrot = Scheme_FowardEuler();
            this.parallel    = any(any(contains(struct2cell(ver),'Parallel Computing Toolbox')));
            this.workers     = parcluster('local').NumWorkers;
            this.auto_step   = true;
        end
        
        %------------------------------------------------------------------
        function setParticleProps(this,particle)
            particle.setSurface();
            particle.setVolume();
            particle.setMass();
            particle.setMInertia();
            if (~isempty(this.gravity))
                particle.setWeight(this.gravity);
            end
        end
        
        %------------------------------------------------------------------
        function runAnalysis(this)
            
        end
    end
end