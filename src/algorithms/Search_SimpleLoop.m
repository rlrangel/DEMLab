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
    
    %% Public methods: implementation of superclass declarations
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
                    
                    % Check for existing interaction
                    interact = intersect(p1.interacts,p2.interacts);
                    if (isempty(interact))
                        % Create new particle-particle interaction if needed
                        this.createInteractPP(drv,p1,p2);
                    else
                        % Check distance
                        if (interact.bin_kinematics.distBtwSurf(p1,p2) < 0)
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
                    
                    % Check for existing interaction
                    interact = intersect(p1.interacts,w.interacts);
                    if (isempty(interact))
                        % Create new particle-wall interaction if needed
                        this.createInteractPW(drv,p1,w);
                    else
                        % Check distance
                        if (interact.bin_kinematics.distBtwSurf(p1,w) < 0)
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
            % Create binary kinematics object to check distance
            kin = BinKinematics_PP();
            if (kin.distBtwSurf(p1,p2) >= 0)
                delete(kin);
                return;
            end
            
            % Create new object by copying base object
            interact = copy(this.b_interact);
            
            % Set handles to interecting elements and kinematics model
            interact.elem1 = p1;
            interact.elem2 = p2;
            interact.bin_kinematics = kin;
            
            % Set effective contact parameters
            interact.bin_kinematics.setEffParams(interact);
            
            % Add handle of new object to both elements and global list
            p1.interacts(end+1)  = interact;
            p2.interacts(end+1)  = interact;
            drv.interacts(end+1) = interact;
        end
        
        %------------------------------------------------------------------
        function createInteractPW(this,drv,p,w)
            % Create binary kinematics object to check distance
            switch w.type
                case w.LINE2D
                    kin = BinKinematics_Wlin();
                case w.CIRCLE
                    kin = BinKinematics_Wcirc();
            end
            if (kin.distBtwSurf(p,w) >= 0)
                delete(kin);
                return;
            end
            
            % Create new object by copying base object
            interact = copy(this.b_interact);
            
            % Set handles to interecting elements and kinematics model
            interact.elem1 = p;
            interact.elem2 = w;
            interact.bin_kinematics = kin;
            
            % Set effective contact parameters
            interact.bin_kinematics.setEffParams(interact);
            
            % Add handle of new object to both elements and global list
            p.interacts(end+1)   = interact;
            w.interacts(end+1)   = interact;
            drv.interacts(end+1) = interact;
        end
    end
end