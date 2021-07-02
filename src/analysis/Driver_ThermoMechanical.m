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
            this.scheme_temp = Scheme_FowardEuler();
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
            particle.setTInertia();
            if (~isempty(this.gravity))
                particle.setWeight(this.gravity);
            end
        end
        
        %------------------------------------------------------------------
        function runAnalysis(this)
            while (this.time < this.max_time && this.step < this.max_step)
                % Update time and step
                this.time = this.time + this.time_step;
                this.step = this.step + 1;
                
                % Interactions search
                if (this.step ~= 1)
                    this.search.execute(this);
                end
                
                % Loop over interactions
                for i = 1:this.n_interacts
                    interact = this.interacts(i);
                    interact.bin_kinematics.evalRelPosVel(interact,this.time_step);
                    interact.contact_force_normal.evalForces(interact);
                    interact.contact_force_tangent.evalForces(interact);
                end
                
                % Loop over particles
                for i = 1:this.n_particles
                    
                end
                
            end
        end
    end
end