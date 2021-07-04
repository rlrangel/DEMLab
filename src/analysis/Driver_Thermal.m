%% Driver_Thermal class
%
%% Description
%
%% Implementation
%
classdef Driver_Thermal < Driver
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Time integration
        scheme_temp Scheme = Scheme.empty;   % object of the Scheme class for temperature
    end
    
    %% Constructor method
    methods
        function this = Driver_Thermal()
            this = this@Driver(Driver.THERMAL);
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
            this.n_interacts = 0;
            this.n_materials = 0;
            this.n_prescond  = 0;
            this.scheme_temp = Scheme_EulerForward();
            this.parallel    = any(any(contains(struct2cell(ver),'Parallel Computing Toolbox')));
            this.workers     = parcluster('local').NumWorkers;
            this.auto_step   = true;
        end
        
        %------------------------------------------------------------------
        function setParticleProps(~,particle)
            particle.setSurface();
            particle.setVolume();
            particle.setMass();
            particle.setTInertia();
        end
        
        %------------------------------------------------------------------
        function runAnalysis(this)
            while (this.time < this.max_time && this.step < this.max_step)
                % Update time and step
                this.time = this.time + this.time_step;
                this.step = this.step + 1;
                
                % Loop over all interactions and particles
                this.interactionLoop();
                this.particleLoop();
            end
        end
        
        %------------------------------------------------------------------
        function interactionLoop(this)
            % Properties accessed in parallel loop
            interacts = this.interacts;
            step = this.step;
            
            % Loop over all interactions
            parfor i = 1:this.n_interacts
                int = interacts(i);
                
                % Evaluate contact interactions
                if (int.kinematics.separ < 0)
                    % Constant parameters needed to be set only once
                    if (step == 1)
                        int.contact_conduction.setParameters(int);
                        int.kinematics.setContactArea(int);
                        int.kinematics.is_contact = true;
                        int.kinematics.dir_n      =  int.kinematics.dir / int.kinematics.dist;
                        int.kinematics.ovlp_n     = -int.kinematics.separ;
                    end
                    
                    % Evaluate heat transfer and add results to particles
                    int.contact_conduction.evalHeatRate(int);
                    int.kinematics.addContactConductionToParticles(int);
                end
            end
        end
        
        %------------------------------------------------------------------
        function particleLoop(this)
            % Properties accessed in parallel loop
            particles = this.particles;
            time      = this.time;
            time_step = this.time_step;
            
            % Loop over all particles
            parfor i = 1:this.n_particles
                p = particles(i);
                
                % Add prescribed conditions
                p.addPCHeatFlux(time);
                p.addPCHeatRate(time);
                
                % Evaluate Newton and energy balance equations
                p.computeTempChange();
                
                % Numerical integration
                this.scheme_temp.updateTemperature(p,time_step);
            end
        end
    end
end