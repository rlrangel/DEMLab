%% Search_SimpleLoop class
%
%% Description
%
% This is a sub-class of the <search.html Search> class for the
% implementation of the interaction search algorithm *Simple Loop*.
%
% This algorithm performs an outer loop over all particles and searches for
% their interactions through inner loops over all particles with a higher
% ID number and all walls.
%
% The reference element of each interaction (element 1) is the particle
% with smaller ID number.
%
% For each interaction found, a binary <interact.html Interaction> object
% is created to manage the mechanical and / or thermal interaction between
% both elements.
%
classdef Search_SimpleLoop < Search
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Base objects for kinematics
        kinpp_sph      BinKinematics = BinKinematics.empty;   % sphere particle - sphere particle
        kinpw_sph_line BinKinematics = BinKinematics.empty;   % sphere particle - line wall
        kinpw_sph_circ BinKinematics = BinKinematics.empty;   % sphere particle - circle wall
        kinpp_cyl      BinKinematics = BinKinematics.empty;   % cylinder particle - sphere particle
        kinpw_cyl_line BinKinematics = BinKinematics.empty;   % cylinder particle - line wall
        kinpw_cyl_circ BinKinematics = BinKinematics.empty;   % cylinder particle - circle wall
    end
    
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
            this.freq           = 1;
            this.done           = false;
            this.cutoff         = 0;
            this.kinpp_sph      = BinKinematics_SphereSphere();
            this.kinpw_sph_line = BinKinematics_SphereWlin();
            this.kinpw_sph_circ = BinKinematics_SphereWcirc();
            this.kinpp_cyl      = BinKinematics_CylinderCylinder();
            this.kinpw_cyl_line = BinKinematics_CylinderWlin();
            this.kinpw_cyl_circ = BinKinematics_CylinderWcirc();
        end
        
        %------------------------------------------------------------------
        function execute(this,drv)
            % Set flags
            this.done = true;
            rmv       = false;
            
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
                    if (any(p1.neigh_p == p2.id))
                        % Get interaction object
                        int = findobj(p1.interacts,'elem2',p2);
                        
                        % Compute separation between elements
                        int.kinemat = int.kinemat.setRelPos(p1,p2);
                        
                        % Check if separation is greater than cutoff distance
                        % Assumption: cutoff ratio applies to maximum radius
                        if (int.kinemat.separ >= this.cutoff * max(p1.radius,p2.radius))
                            % Remove interaction references from elements
                            p1.interacts(p1.interacts==int) = [];
                            p1.neigh_p(p1.neigh_p==p2.id)   = [];
                            p2.interacts(p2.interacts==int) = [];
                            p2.neigh_p(p2.neigh_p==p1.id)   = [];
                            
                            % Delete interaction object
                            delete(int);
                            rmv = true;
                        end
                    else
                        % Create new particle-particle interaction if needed
                        this.createInteractPP(drv,p1,p2);
                    end
                end
                
                % Inner loop over all walls
                for j = 1:drv.n_walls
                    w = drv.walls(j);
                    
                    % Check for existing interaction
                    if (any(p1.neigh_w == w.id))
                        % Get interaction object
                        int = findobj(p1.interacts,'elem2',w);
                        
                        % Compute separation between elements
                        int.kinemat = int.kinemat.setRelPos(p1,w);
                        
                        % Check if separation is greater than cutoff distance
                        % Assumption: cutoff ratio applies to particle radius
                        if (int.kinemat.separ >= this.cutoff * p1.radius)
                            % Remove interaction references from particle
                            p1.interacts(p1.interacts==int) = [];
                            p1.neigh_w(p1.neigh_w==w.id)    = [];
                            
                            % Delete interaction object
                            delete(int);
                            rmv = true;
                        end
                    else
                        % Create new particle-wall interaction if needed
                        this.createInteractPW(drv,p1,w);
                    end
                end
            end
            
            % Erase handles to removed interactions from global list
            if (rmv)
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
            % Compute separation between particles surfaces
            % PS: This is exclusive for round particles to avoid calling the
            %     base kinematic object (a bit slower).
            %     For other shapes, the base kinematic object will be used.
            dir   = p2.coord - p1.coord;
            dist  = norm(dir);
            separ = dist - p1.radius - p2.radius;
            
            % Check if interaction exists
            % Assumption: cutoff ratio applies to maximum radius
            if (separ >= this.cutoff * max(p1.radius,p2.radius))
                return;
            end
            
            % Create new interaction object by copying base object
            int = copy(this.b_interact);
            
            % Set handles to interecting elements
            int.elem1 = p1;
            int.elem2 = p2;
            
            % Create binary kinematic object
            kin = this.createPPKinematic(p1,dir,dist,separ);
            kin.setEffParams(int);
            int.kinemat = kin;
            
            % Add references of new interaction to both elements and global list
            p1.interacts(end+1)  = int;
            p1.neigh_p(end+1)    = p2.id;
            p2.interacts(end+1)  = int;
            p2.neigh_p(end+1)    = p1.id;
            drv.interacts(end+1) = int;
        end
        
        %------------------------------------------------------------------
        function createInteractPW(this,drv,p,w)
            % Check elements separation and copy kinematics object from base object
            % Assumption: cutoff ratio applies to particle radius
            switch (this.pwInteractionType(p,w))
                case 1
                    this.kinpw_sph_line.setRelPos(p,w);
                    if (this.kinpw_sph_line.separ >= this.cutoff * p.radius)
                        return;
                    end
                    kin = copy(this.kinpw_sph_line);
                case 2
                    this.kinpw_sph_circ.setRelPos(p,w);
                    if (this.kinpw_sph_circ.separ >= this.cutoff * p.radius)
                        return;
                    end
                    kin = copy(this.kinpw_sph_circ);
                case 3
                    this.kinpw_cyl_line.setRelPos(p,w);
                    if (this.kinpw_cyl_line.separ >= this.cutoff * p.radius)
                        return;
                    end
                    kin = copy(this.kinpw_cyl_line);
                case 4
                    this.kinpw_cyl_circ.setRelPos(p,w);
                    if (this.kinpw_cyl_circ.separ >= this.cutoff * p.radius)
                        return;
                    end
                    kin = copy(this.kinpw_cyl_circ);
            end
            
            % Create new interaction object by copying base object
            int = copy(this.b_interact);
            
            % Set handles to interecting elements
            int.elem1 = p;
            int.elem2 = w;
            
            % Set binary kinematic object
            kin.setEffParams(int);
            int.kinemat = kin;
            
            % Set flag for insulated interaction
            int.insulated = w.insulated;
            
            % Add references of new interaction to particle and global list
            p.interacts(end+1)   = int;
            p.neigh_w(end+1)     = w.id;
            drv.interacts(end+1) = int;
        end
    end
end