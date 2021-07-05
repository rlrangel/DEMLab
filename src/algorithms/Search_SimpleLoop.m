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
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.freq     = 1;
            this.done     = false;
            this.max_dist = 0;
        end
        
        %------------------------------------------------------------------
        function execute(this,drv)
            if (mod(drv.step,this.freq) ~= 0)
                return;
            end
            
            % Set flags
            this.done = true;
            removed   = false;
            
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
                    int = intersect(p1.interacts,p2.interacts);
                    if (isempty(int))
                        % Create new particle-particle interaction if needed
                        this.createInteractPP(drv,p1,p2);
                    else
                        % Compute and check separation between elements
                        int.kinemat = int.kinemat.setRelPos(p1,p2);
                        if (int.kinemat.separ >= this.max_dist)
                            % Remove handles from interacting elements
                            p1.interacts(p1.interacts==int) = [];
                            p2.interacts(p2.interacts==int) = [];
                            
                            % Delete interaction object
                            removed = true;
                            delete(int);
                        end
                    end
                end
                
                % Inner loop over all walls
                for j = 1:drv.n_walls
                    w = drv.walls(j);
                    
                    % Check for existing interaction
                    int = intersect(p1.interacts,w.interacts);
                    if (isempty(int))
                        % Create new particle-wall interaction if needed
                        this.createInteractPW(drv,p1,w);
                    else
                        % Compute and check separation between elements
                        int.kinemat = int.kinemat.setRelPos(p1,w);
                        if (int.kinemat.separ >= this.max_dist)
                            % Remove handles from interacting elements
                            p1.interacts(p1.interacts==int) = [];
                            w.interacts(w.interacts==int)   = [];    

                            % Delete interaction object
                            removed = true;
                            delete(int);
                        end
                    end
                end
            end
            
            % Remove handle to deleted interactions from global list
            if (removed)
                drv.interacts(~isvalid(drv.interacts)) = [];
                drv.n_interacts = length(drv.interacts);
            end
        end
    end
    
    %% Public methods: Subclass specifics
    methods
        %------------------------------------------------------------------
        function createInteractPP(this,drv,p1,p2)
            % Create binary kinematics object
            kin = BinKinematics_PP();
            
            % Compute and check separation between elements
            kin = kin.setRelPos(p1,p2);
            if (kin.separ >= this.max_dist)
                return;
            end
            
            % Create new object by copying base object
            int = copy(this.b_interact);
            
            % Set handles to interecting elements and kinematics model
            int.elem1   = p1;
            int.elem2   = p2;
            int.kinemat = kin;
            
            % Set kinematics parameters
            int.kinemat.setEffParams(int);
            int.kinemat = int.kinemat.setEndParams();
            
            % Add handle of new object to both elements and global list
            p1.interacts(end+1)  = int;
            p2.interacts(end+1)  = int;
            drv.interacts(end+1) = int;
        end
        
        %------------------------------------------------------------------
        function createInteractPW(this,drv,p,w)
            % Create binary kinematics object
            switch w.type
                case w.LINE2D
                    kin = BinKinematics_PWlin();
                case w.CIRCLE
                    kin = BinKinematics_PWcirc();
            end
            
            % Compute and check separation between elements
            kin = kin.setRelPos(p,w);
            if (kin.separ >= this.max_dist)
                return;
            end
            
            % Create new object by copying base object
            int = copy(this.b_interact);
            
            % Set handles to interecting elements and kinematics model
            int.elem1   = p;
            int.elem2   = w;
            int.kinemat = kin;
            
            % Set kinematics parameters
            int.kinemat.setEffParams(int);
            int.kinemat = int.kinemat.setEndParams();
            
            % Add handle of new object to both elements and global list
            p.interacts(end+1)   = int;
            w.interacts(end+1)   = int;
            drv.interacts(end+1) = int;
        end
    end
end