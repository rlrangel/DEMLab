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
        gravity double = double.empty;   % vector of gravity components value
        
        % Time integration
        scheme_trl  Scheme = Scheme.empty;   % handle to object of Scheme class for translation integration
        scheme_rot  Scheme = Scheme.empty;   % handle to object of Scheme class for rotation integration
        scheme_temp Scheme = Scheme.empty;   % handle to object of Scheme class for temperature integration
    end
    
    %% Constructor method
    methods
        function this = Driver_ThermoMechanical()
            this = this@Driver(Driver.THERMO_MECHANICAL);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
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
            this.nprog       = 1;
            this.nout        = 500;
        end
        
        %------------------------------------------------------------------
        function setParticleProps(this,p)
            p.setSurface();
            p.setVolume();
            p.setMass();
            p.setMInertia();
            p.setTInertia();
            if (~isempty(this.gravity))
                p.setWeight(this.gravity);
                p.addWeight();
            end
        end
        
        %------------------------------------------------------------------
        function runAnalysis(this)
            while (this.time < this.max_time)
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
                
                % Print progress and store results
                this.printProgress();
                this.storeResults();
            end
        end
    end
        
   %% Public methods: Subclass specifics
    methods
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
                    int.kinemat = int.kinemat.setRelPos(int.elem1,int.elem2);
                end
                
                % Evaluate contact interactions
                if (int.kinemat.separ < 0)
                    % Update overlap parameters
                    int.kinemat = int.kinemat.setOverlaps(int,time_step);
                    
                    % Update contact area
                    int.kinemat = int.kinemat.setContactArea(int);
                    
                    % Set initial contact parameters
                    if (~int.kinemat.is_contact)
                        % Initialize contact
                        int.kinemat = int.kinemat.setCollisionParams(time);
                        
                        % Initialize interaction parameters values
                        int.cforcen = int.cforcen.setParameters(int);
                        int.cforcet = int.cforcet.setParameters(int);
                        int.cconduc = int.cconduc.setParameters(int);
                    end
                    
                    % Update contact duration
                    int.kinemat.contact_time = time - int.kinemat.contact_start;
                    
                    % Compute interaction results
                    int.cforcen = int.cforcen.evalForce(int);
                    int.cforcet = int.cforcet.evalForce(int);
                    int.cconduc = int.cconduc.evalHeatRate(int);
                    
                    % Add interaction results to particles
                    int.kinemat.addContactForceToParticles(int);
                    int.kinemat.addContactTorqueToParticles(int);
                    int.kinemat.addContactConductionToParticles(int);
                    
                % Evaluate noncontact interactions
                else
                    % Finalize contact
                    if (int.kinemat.is_contact)
                        int.kinemat = int.kinemat.setEndParams();
                    end
                end
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
                
                % Evaluate equations of motion and energy balance
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
                
                % Reset forcing terms for next step
                p.resetForcingTerms();
            end
            
            % Erase handles to removed particles from global list and model parts
            if (removed)
                this.eraseHandlesToRemovedParticle;
            end
        end
    end
end