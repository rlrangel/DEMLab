%% Search_SimpleLoop class
%
%% Description
%
% This is a sub-class of the <search.html Search> class for the
% implementation of the interaction search algorithm *Simple Loop*.
%
% This algorithm performs an outer loop over all particles and searches for
% interacting particles and walls through inner loops over all particles
% with a higher ID number and all walls.
%
% For each interaction found, a binary <interact.html Interaction> object
% is created to manage the mechanical and / or thermal interaction between
% both elements.
%
classdef Search_SimpleLoop < Search
    %% Constructor method
    methods
        function this = Search_SimpleLoop()
            this = this@Search(Search.SIMPLE_LOOP);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
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
            end
            
            % Update total number of interactions
            drv.n_interacts = length(drv.interacts);
        end
    end
    
    %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function createInteractPP(this,drv,p1,p2)
            % Create binary kinematic object
            kin = this.createPPKinematic(p1,p2);
            
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
            % Create binary kinematic object
            kin = this.createPWKinematic(p,w);
            
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
        
        %------------------------------------------------------------------
        function kin = createPPKinematic(~,p1,p2)
            switch p1.type
                case p1.SPHERE
                    switch p2.type
                        case p2.SPHERE
                            kin = BinKinematics_SphereSphere();
                    end
                case p1.CYLINDER
                    switch p2.type
                        case p2.CYLINDER
                            kin = BinKinematics_CylinderCylinder();
                    end
            end
        end
        
        %------------------------------------------------------------------
        function kin = createPWKinematic(~,p,w)
            switch p.type
                case p.SPHERE
                    switch w.type
                        case w.LINE
                            kin = BinKinematics_SphereWlin();
                        case w.CIRCLE
                            kin = BinKinematics_SphereWcirc();
                    end
                case p.CYLINDER
                    switch w.type
                        case w.LINE
                            kin = BinKinematics_CylinderWlin();
                        case w.CIRCLE
                            kin = BinKinematics_CylinderWcirc();
                    end
            end
        end
    end
end