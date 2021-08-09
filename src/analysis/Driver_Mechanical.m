%% Driver_Mechanical class
%
%% Description
%
% This is a sub-class of the <driver.html Driver> class for the
% implementation of the *Mechanical* analysis driver.
%
% In this type of analysis only the mechanical behavior of particles is
% simulated (kinetics and kinematics).
%
% This class is responsible for solving all the time steps of a mechanical
% simulation by performing loops over all interactions, particles and walls
% in order to compute the changes of motion.
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
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.n_mparts    = 0;
            this.n_particles = 0;
            this.n_walls     = 0;
            this.n_interacts = 0;
            this.n_materials = 0;
            this.auto_step   = false;
            this.search      = Search_SimpleLoop();
            this.scheme_trl  = Scheme_EulerForward();
            this.scheme_rot  = Scheme_EulerForward();
            this.parallel    = any(any(contains(struct2cell(ver),'Parallel Computing Toolbox')));
            this.workers     = parcluster('local').NumWorkers;
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
        function dt = criticalTimeStep(~,p)
            % Li et al. A comparison of discrete element simulations and experiments for sandpiles composed of spherical particles, 2005
            dt = pi * p.radius * sqrt(p.material.density / p.material.shear) / (0.8766 + 0.163 * p.material.poisson);
            
            % Apply reduction coefficient
            dt = dt * 0.01;
            
            % Limit time step
            if (dt > 0.001)
                dt = 0.001;
            end
        end
        
        %------------------------------------------------------------------
        function process(this)
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
                if (mod(this.step,this.search.freq) == 1)
                    this.search.execute(this);
                end
                
                % Loop over all interactions, particles and walls
                this.interactionLoop();
                this.particleLoop();
                this.wallLoop();
                
                % Adjustments before next step
                this.search.done = false;
                
                % Print progress
                this.printProgress();
            end
        end
    end
    
   %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function interactionLoop(this)            
            for i = 1:this.n_interacts
                int = this.interacts(i);
                
                % Update relative position (if not already done in search)
                if (~this.search.done)
                    int.kinemat = int.kinemat.setRelPos(int.elem1,int.elem2);
                end
                
                % Evaluate contact interactions
                if (int.kinemat.separ < 0)
                    % Update overlap parameters
                    int.kinemat = int.kinemat.setOverlaps(int,this.time_step);
                    
                    % Update contact area
                    int.kinemat = int.kinemat.setContactArea(int);
                    
                    % Set initial contact parameters
                    if (~int.kinemat.is_contact)
                        % Initialize contact
                        int.kinemat = int.kinemat.setInitContactParams(this.time);
                        
                        % Initialize constant interaction parameters values
                        int.setCteParamsMech();
                    end
                    
                    % Update contact duration
                    int.kinemat.contact_time = this.time - int.kinemat.contact_start;
                    
                    % Compute interaction results
                    int.evalResultsMech();
                    
                    % Add interaction results to particles
                    int.addResultsMech();
                    
                % Evaluate noncontact interactions
                else
                    % Finalize contact
                    if (int.kinemat.is_contact)
                        int.kinemat = int.kinemat.setEndContactParams();
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function particleLoop(this)
            % Initialize flags
            rmv = false;
            
            % Loop over all particles
            for i = 1:this.n_particles
                p = this.particles(i);
                
                % Set flags for fixed motion
                p.setFixedMech(this.time);
                
                % Solve translational motion
                if (p.free_trl)
                    % Add global conditions
                    p.addWeight();
                    if (~isempty(this.damp_trl))
                        p.addGblDampTransl(this.damp_trl);
                    end
                    
                    % Add prescribed conditions
                    p.addPCForce(this.time);
                    
                    % Evaluate equation of motion
                    p.setAccelTrl();
                    
                    % Numerical integration
                    this.scheme_trl.updatePosition(p,this.time_step);
                else
                    % Set fixed translation
                    p.setFCTranslation(this.time,this.time_step);
                end
                
                % Remove particles not respecting bbox and sinks
                if (this.removeParticle(p))
                    rmv = true;
                    continue;
                end
                
                % Solve rotational motion
                if (p.free_rot)
                    % Add global conditions
                    if (~isempty(this.damp_rot))
                        p.addGblDampRot(this.damp_rot);
                    end
                    
                    % Add prescribed conditions
                    p.addPCTorque(this.time);
                    
                    % Evaluate equation of motion
                    p.setAccelRot();
                    
                    % Numerical integration
                    this.scheme_rot.updateOrientation(p,this.time_step);
                else
                    % Set fixed rotation
                    p.setFCRotation(this.time,this.time_step);
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
            if (rmv)
                this.eraseHandlesToRemovedParticle;
            end
        end
        
        %------------------------------------------------------------------
        function wallLoop(this)
            for i = 1:this.n_walls
                w = this.walls(i);
                
                % Set fixed motion
                w.setFixedMotion(this.time);
                w.setFCMotion(this.time,this.time_step);
                
                % Store results
                if (this.store)
                    this.result.storeWallPosition(w);
                end
            end
        end
    end
end