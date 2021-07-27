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
        gravity  double = double.empty;   % vector of gravity components value
        damp_trl double = double.empty;   % damping for translational motion
        damp_rot double = double.empty;   % damping for rotational motion
        
        % Time integration
        scheme_trl Scheme = Scheme.empty;   % handle to object of Scheme class for translation integration
        scheme_rot Scheme = Scheme.empty;   % handle to object of Scheme class for rotation integration
    end
    
    %% Constructor method
    methods
        function this = Driver_Mechanical()
            this = this@Driver(Driver.MECHANICAL);
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
            this.search      = Search_SimpleLoop();
            this.scheme_trl  = Scheme_EulerForward();
            this.scheme_rot  = Scheme_EulerForward();
            this.parallel    = any(any(contains(struct2cell(ver),'Parallel Computing Toolbox')));
            this.workers     = parcluster('local').NumWorkers;
            this.auto_step   = false;
            this.result      = Result();
            this.nprog       = 1;
            this.nout        = 500;
        end
        
        %------------------------------------------------------------------
        function setParticleProps(this,p)
            p.setSurface();
            p.setVolume();
            p.setMass();
            p.setMInertia();
            if (~isempty(this.gravity))
                p.setWeight(this.gravity);
            end
        end
        
        %------------------------------------------------------------------
        function runAnalysis(this)
            while (this.time < this.max_time)
                % Update time and step
                this.time = this.time + this.time_step;
                this.step = this.step + 1;
                
                % Store current time and step to result arrays
                if (this.storeResults())
                    this.store = true;
                    this.result.storeGlobalParams(this);
                else
                    this.store = false;
                end
                
                % Interactions search
                if (this.step ~= 1)
                    this.search.execute(this);
                end
                
                % Loop over all interactions, particles and walls
                this.interactionLoop();
                this.particleLoop();
                this.wallLoop();
                
                % Print progress
                this.printProgress();
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
            for i = 1:this.n_interacts
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
                    end
                    
                    % Update contact duration
                    int.kinemat.contact_time = time - int.kinemat.contact_start;
                    
                    % Compute interaction results
                    int.cforcen = int.cforcen.evalForce(int);
                    int.cforcet = int.cforcet.evalForce(int);
                    
                    % Add interaction results to particles
                    int.kinemat.addContactForceToParticles(int);
                    int.kinemat.addContactTorqueToParticles(int);
                    
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
            
            % Initialize flags
            removed = false;
            
            % Loop over all particles
            for i = 1:this.n_particles
                p = particles(i);
                
                % Set flag for free particle
                p.setFreeMech(this.time);
                
                % Solver mechanical state
                if (p.free_mech)
                    % Add global conditions
                    p.addWeight();
                    if (~isempty(this.damp_trl))
                        p.addGblDampTransl(this.damp_trl);
                    end
                    if (~isempty(this.damp_rot))
                        p.addGblDampRot(this.damp_rot);
                    end
                    
                    % Add prescribed conditions
                    p.addPCForce(time);
                    p.addPCTorque(time);

                    % Evaluate equation of motion
                    p.computeAccelTrl();
                    p.computeAccelRot();

                    % Numerical integration
                    this.scheme_trl.updatePosition(p,time_step);
                    this.scheme_rot.updateOrientation(p,time_step);
                else
                    % Set fixed conditions
                    p.setFCVelocity(time,time_step);
                end
                
                % Remove particles not respecting bbox and sinks
                if (this.removeParticle(p))
                    removed = true;
                    continue;
                end
                
                % Store results
                if (this.store)
                    this.result.storeParticlePosition(p);
                    this.result.storeParticleMotion(p);
                    this.result.storeParticleForce(p);
                end
                
                % Reset forcing terms for next step
                p.resetForcingTerms();
            end
            
            % Erase handles to removed particles from global list and model parts
            if (removed)
                this.eraseHandlesToRemovedParticle;
            end
        end
        
        %------------------------------------------------------------------
        function wallLoop(this)
            % Properties accessed in parallel loop
            walls     = this.walls;
            time      = this.time;
            time_step = this.time_step;
            
            % Loop over all walls
            for i = 1:this.n_walls
                w = walls(i);
                
                % Set fixed motion
                w.setFreeMech(this.time);
                if (~w.free_mech)
                    w.setFCVelocity(time,time_step);
                end
                
                % Store results
                if (this.store)
                    this.result.storeWallPosition(w);
                end
            end
        end
    end
end