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
                
                % Loop over all interactions and particles
                this.interactionLoop();
                this.particleLoop();
                
                % Adjustments before next step
                this.search.done = false;
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
                        int.kinematics.is_contact = true;
                        
                        % Save collision information
                        int.kinematics.contact_start = time;
                        int.kinematics.v0_n = int.kinematics.vel_n;
                        
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
                    
                    % Convert vector components to global system
                    % coeff of restitution
                    
                elseif (int.kinematics.is_contact)
                    % Finalize contact
                    int.kinematics.is_contact = false;
                end
            end
        end
        
        %------------------------------------------------------------------
        function particleLoop(this)
            % Properties accessed in parallel loop
            particles = this.particles;
            time      = this.time;
            
            % Loop over all particles
            parfor i = 1:this.n_particles
                p = particles(i);
                
                % Add interactions results (MOVE TO INTERACTIONS LOOP ?!?!)
                for j = i:length(p.interacts)
                    int = p.interacts(j);
                    
                    % Determine sign
                    if (isequal(p,int.elem1))
                        sign = 1;
                    else
                        sign = -1;
                    end
                    
                    % Add contact interaction results
                    if (int.is_contact)
                        p.force     = sign * int.contact_force_norm.total_force;
                        p.torque    = sign * int.contact_force_tang.total_force;
                        p.heat_rate = sign * int.contact_conduction.total_hrate;
                    end
                end
                
                % Add global conditions
                p.addWeight();
                
                % Add prescribed conditions
                p.addPCForce(time);
                p.addPCTorque(time);
                p.addPCHeatFlux(time);
                p.addPCHeatRate(time);
                
                % Numerical integration
                
                
                
                
            end
        end
    end
end