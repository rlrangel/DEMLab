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
        scheme_trl  Scheme = Scheme.empty;   % object of the Scheme class for translation
        scheme_rot  Scheme = Scheme.empty;   % object of the Scheme class for rotation
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
            this.scheme_trl  = Scheme_EulerForward();
            this.scheme_rot  = Scheme_EulerForward();
            this.scheme_temp = Scheme_EulerForward();
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
                
                % Loop over all interactions and particles
                this.interactionLoop();
                this.particleLoop();
            end
        end
        
        %------------------------------------------------------------------
        function interactionLoop(this)
            % Properties accessed in parallel loop
            interacts   = this.interacts;
            time        = this.time;
            time_step   = this.time_step;
            done_search = this.search.done;
            
            % Loop over all interactions
            parfor i = 1:this.n_interacts
                int = interacts(i);
                
                % Update relative position (if not already done in search)
                if (~done_search)
                    int.kinematics.setRelPos(int.elem1,int.elem2);
                end
                
                % Evaluate contact interactions
                if (int.kinematics.separ < 0)
                    % Update overlap parameters
                    int.kinematics.evalOverlaps(int,time_step);
                    
                    % Update contact area
                    int.kinematics.setContactArea(int);
                    
                    % Set initial contact parameters
                    if (~int.kinematics.is_contact)
                        % Initialize contact
                        int.kinematics.setCollisionParams(time);
                        
                        % Initialize interaction parameters values
                        int.contact_force_norm.setParameters(int);
                        int.contact_force_tang.setParameters(int);
                        int.contact_conduction.setParameters(int);
                    end
                    
                    % Update contact duration
                    int.kinematics.contact_time = time - int.kinematics.contact_start;
                    
                    % Evaluate forces, torques and heat transfer
                    int.contact_force_norm.evalForce(int);
                    int.contact_force_tang.evalForce(int);
                    int.contact_conduction.evalHeatRate(int);
                    
                    % Add interaction results to particles
                    int.kinematics.addContactForceToParticles(int);
                    int.kinematics.addContactTorqueToParticles(int);
                    int.kinematics.addContactConductionToParticles(int);
                    
                % Evaluate noncontact interactions
                else
                    % Finalize contact
                    if (int.kinematics.is_contact)
                        int.kinematics.setEndParams();
                    end
                end
                % Try to evaluate both interacting particles here,
                % and set a flag(the time step) to avoid doing it again
                % Also do the integration of these particles.
            end
            
            % Adjustments before next step
            this.search.done = false;
        end
        
        %------------------------------------------------------------------
        function particleLoop(this)
            % Properties accessed in parallel loop
            particles = this.particles;
            time      = this.time;
            time_step = this.time_step;
            removed   = false;
            
            % Loop over all particles
            parfor i = 1:this.n_particles
                p = particles(i);
                
                % Add global conditions
                p.addWeight();
                
                % Add prescribed conditions
                p.addPCForce(time);
                p.addPCTorque(time);
                p.addPCHeatFlux(time);
                p.addPCHeatRate(time);
                
                % Evaluate Newton and energy balance equations
                p.computeAccelTrl();
                p.computeAccelRot();
                p.computeTempChange();
                
                % Numerical integration
                this.scheme_trl.updatePosition(p,time_step);
                this.scheme_rot.updateOrientation(p,time_step);
                this.scheme_temp.updateTemperature(p,time_step);
                
                % Remove particles not respecting bbox and sinks
                if (this.removeParticle(p))
                    removed = true;
                end
            end
            
            % Erase handles to removed particles from global list and model parts
            if (removed)
                this.eraseHandlesToRemovedParticle;
            end
        end
    end
end