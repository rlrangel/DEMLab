%% Search_SimpleLoop class
%
%% Description
%
%% Implementation
%
classdef Search_SimpleLoop < Search
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Search_SimpleLoop()
            this = this@Search(Search.SIMPLE_LOOP);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.freq = 1;
        end
        
        %------------------------------------------------------------------
        function execute(this,drv)
            if (mod(drv.step,this.freq) ~= 0)
                return;
            end
            
            % Outer loop over reference particles
            %parfor i = 1:drv.n_particles
            for i = 1:drv.n_particles
                p1 = drv.particles(i);
                
                % Inner loop over all other particles with higher ID
                for j = 1:drv.n_particles
                    p2 = drv.particles(j);
                    if (p1.id >= p2.id)
                        continue;
                    end
                    
                    % Distance between surfaces
                    d = norm(p1.coord-p2.coord) - p1.radius - p2.radius;
                    
                    % Check for existing interaction
                    interact = intersect(p1.interacts,p2.interacts);
                    if (isempty(interact))
                        % Check distance
                        if (d >= 0)
                            continue;
                        end
                        
                        % Create new object by copying base object
                        interact = copy(this.b_interact);
                        
                        % Set handles to interecting particles
                        interact.element1 = p1;
                        interact.element2 = p2;
                        
                        % Add handle of new object to both particles and global list
                        p1.interacts(end+1)  = interact;
                        p2.interacts(end+1)  = interact;
                        drv.interacts(end+1) = interact;
                        drv.n_interacts      = drv.n_interacts + 1;
                    else
                        % Check distance
                        if (d < 0)
                            continue;
                        end
                        
                        % Remove handles from interacting particles
                        p1.interacts(p1.interacts==interact) = [];
                        p2.interacts(p2.interacts==interact) = [];
                        drv.n_interacts = drv.n_interacts - 1;
                        
                        
                        % Delete interaction object
                        delete(interact);
                    end
                end
                
                % Inner loop over all walls
                for j = 1:drv.n_walls
                    w = drv.walls(j);
                    
                    % Distance between particle surface and wall
                    d = w.distanceFromParticle(p1);
                    
                    % Check for existing interaction
                    interact = intersect(p1.interacts,w.interacts);
                    if (isempty(interact))
                        % Check distance
                        if (d >= 0)
                            continue;
                        end
                        
                    else
                        % Check distance
                        if (d < 0)
                            continue;
                        end
                        
                    end
                end
            end
            
            % Remove handle to deleted interactions from global list
            % (cannot be done inside the loop due to parallelization)
            drv.interacts(~isvalid(drv.interacts)) = [];
        end
    end
end