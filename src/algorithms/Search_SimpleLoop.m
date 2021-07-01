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
                        
                        % Create new particle-particle interaction
                        this.createInteractPP(drv,p1,p2);
                    else
                        % Check distance
                        if (d < 0)
                            continue;
                        end
                        
                        % Remove handles from interacting elements
                        p1.interacts(p1.interacts==interact) = [];
                        p2.interacts(p2.interacts==interact) = [];    
                        
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
                        
                        % Create new particle-wall interaction
                        this.createInteractPW(drv,p1,w);
                    else
                        % Check distance
                        if (d < 0)
                            continue;
                        end
                        
                        % Remove handles from interacting elements
                        p1.interacts(p1.interacts==interact) = [];
                        w.interacts(w.interacts==interact)   = [];    
                        
                        % Delete interaction object
                        delete(interact);
                    end
                end
            end
            
            % Remove handle to deleted interactions from global list
            drv.interacts(~isvalid(drv.interacts)) = [];
            drv.n_interacts = length(drv.interacts);
        end
        
        %------------------------------------------------------------------
        function createInteractPP(this,drv,p1,p2)
            % Create new object by copying base object
            interact = copy(this.b_interact);
            
            % Set handles to interecting elements
            interact.elem1 = p1;
            interact.elem2 = p2;
            
            % Create contact kinematics model
            interact.contact_kinematics = ContactKinematics_PP();
            
            % Set effective contact parameters
            interact.contact_kinematics.setEffParams(interact);
            
            % Add handle of new object to both elements and global list
            p1.interacts(end+1)  = interact;
            p2.interacts(end+1)  = interact;
            drv.interacts(end+1) = interact;
        end
        
        %------------------------------------------------------------------
        function createInteractPW(this,drv,p,w)
            % Create new object by copying base object
            interact = copy(this.b_interact);
            
            % Set handles to interecting elements
            interact.elem1 = p;
            interact.elem2 = w;
            
            % Create contact kinematics model
            interact.contact_kinematics = ContactKinematics_PW();
            
            % Set effective contact parameters
            interact.contact_kinematics.setEffParams(interact);
            
            % Add handle of new object to both elements and global list
            p.interacts(end+1)   = interact;
            w.interacts(end+1)   = interact;
            drv.interacts(end+1) = interact;
        end
    end
end