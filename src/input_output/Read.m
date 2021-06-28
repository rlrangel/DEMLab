%% Read class
%
%% Description
%
%% Implementation
%
classdef Read < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Read()
            
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function [status,drv] = execute(this,path,fid)
            status = 1;
            drv = [];
            
            % Parse json file
            file_txt = char(fread(fid,inf)');
            fclose(fid);
            if (isempty(file_txt))
                fprintf(2,'Empty project parameters file.\n');
                status = 0; return;
            end
            json = jsondecode(file_txt);
            
            % Feed simulation data
            if (status)
                [status,drv,model_parts_file] = this.getProblemData(json);
            end
            if (status)
                status = this.getModelParts(drv,path,model_parts_file);
            end
            if (status)
                status = this.getSolverParam(json,drv);
            end
            if (status)
                status = this.getBoundingBox(json,drv);
            end
            if (status)
                status = this.getGlobalCondition(json,drv);
            end
            if (status)
                status = this.getInitialCondition(json,drv);
            end
            if (status)
                status = this.getMaterial(json,drv);
            end
            
            % Final checks:
            % All particles have geometric property (radius for disk).
            % All particles have a material;
            % Material properties required by the analysis/models;
        end
        
        %------------------------------------------------------------------
        function [status,drv,model_parts_file] = getProblemData(this,json)
            status = 1;
            drv = [];
            model_parts_file = [];
            
            % Check if all fields exist
            if (~isfield(json,'ProblemData'))
                fprintf(2,'Missing data in project parameters file: ProblemData.\n');
                status = 0; return;
            end
            PD = json.ProblemData;
            
            if (~isfield(PD,'name') || ~isfield(PD,'analysis_type') || ~isfield(PD,'dimension') || ~isfield(PD,'model_parts_file'))
                fprintf(2,'Missing data in project parameters file: ProblemData must have name, analysis_type, dimension and model_parts_file.\n');
                status = 0; return;
            end
            
            % Create object of Driver class
            anl = string(PD.analysis_type);
            if (~this.isStringArray(anl,1) || (~strcmp(anl,'mechanical') && ~strcmp(anl,'thermal') && ~strcmp(anl,'thermo_mechanical')))
                fprintf(2,'Invalid data in project parameters file: ProblemData.analysis_type.\n');
                fprintf(2,'Available options: mechanical, thermal, thermo_mechanical.\n');
                status = 0; return;
            end
            if (strcmp(anl,'mechanical'))
                drv = Driver_Mechanical();
            elseif (strcmp(anl,'thermal'))
                drv = Driver_Thermal();
            elseif (strcmp(anl,'thermo_mechanical'))
                drv = Driver_ThermoMechanical();
            end
            
            % Name
            name = string(PD.name);
            if (~this.isStringArray(name,1))
                fprintf(2,'Invalid data in project parameters file: ProblemData.name.\n');
                fprintf(2,'It must be a string with the name representing the simulation.\n');
                status = 0; return;
            end
            drv.name = name;
            
            % Dimension
            dim = PD.dimension;
            if (~this.isDoubleArray(dim,1) || (dim ~= 2 && dim ~= 3))
                fprintf(2,'Invalid data in project parameters file: ProblemData.dimension.\n');
                fprintf(2,'Available options: 2 or 3.\n');
                status = 0; return;
            end
            drv.dimension = dim;
            
            % Model parts file name
            model_parts_file = string(PD.model_parts_file);
            if (~this.isStringArray(model_parts_file,1))
                fprintf(2,'Invalid data in project parameters file: ProblemData.model_parts_file.\n');
                fprintf(2,'It must be a string with the model part file name.\n');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = getModelParts(this,drv,path,file)
            status = 1;
            
            % Open model parts file
            fullname = fullfile(path,file);
            fid = fopen(fullname,'rt');
            if (fid < 0)
                fprintf(2,"Error opening model parts file: %s\n", file);
                fprintf(2,"It must have the same path of the project parameters file.\n");
                status = 0; return;
            end
            
            % Look for tag strings
            while (status == 1 && ~feof(fid))
                line = deblank(fgetl(fid));
                switch line
                    case '%PARTICLES.DISK'
                        status = this.readParticlesDisk(fid,drv);
                    case '%WALLS.LINE2D'
                        status = this.readWallsLine2D(fid,drv);
                    case '%WALLS.CIRCLE'
                        status = this.readWallsCircle(fid,drv);
                    case '%MODELPART'
                        status = this.readModelParts(fid,drv);
                end
            end
            fclose(fid);
            if (status == 0)
                return;
            end
            
            % Check ID numbering
            if (drv.n_particles == 0)
                fprintf(2,"The must have at least one particle.\n");
                status = 0; return;
            elseif (drv.particles(drv.n_particles).id > drv.n_particles)
                fprintf(2,"Invalid numbering of particles: IDs cannot skip numbers.\n");
                status = 0; return;
            end
            
            if (drv.walls(drv.n_walls).id > drv.n_walls)
                fprintf(2,"Invalid numbering of walls: IDs cannot skip numbers.\n");
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readParticlesDisk(this,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: PARTICLES.DISK is only allowed in 2D models.\n");
                status = 0; return;
            end
            
            % Total number of disk particles
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of PARTICLES.DISK.\n");
                fprintf(2,"It must be a positive integer.\n");
                status = 0; return;
            end
            
            % Update total number of particles
            drv.n_particles = drv.n_particles + n;
            
            % Read each particle
            deblank(fgetl(fid)); % go to next line
            for i = 1:n
                if (feof(fid))
                    break;
                end
                line = deblank(fgetl(fid));
                if (isempty(line) || isnumeric(line))
                    break;
                end
                
                % Read all values of current line
                values = sscanf(line,'%f');
                if (length(values) ~= 4 && length(values) ~= 5)
                    fprintf(2,"Invalid data in model parts file: Number of parameters of PARTICLES.DISK.\n");
                    fprintf(2,"It requires 5 parameters: ID, coord X, coord Y, orientation, radius (radius is optional in this file).\n");
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of PARTICLES.DISK.\n");
                    fprintf(2,"It must be a positive integer.\n");
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~this.isDoubleArray(coord,2))
                    fprintf(2,"Invalid data in model parts file: Coordinates of PARTICLES.DISK with ID %d.\n",id);
                    fprintf(2,"It must be a pair of numeric values.\n");
                    status = 0; return;
                end
                
                % Orientation angle
                orient = values(4);
                if (~this.isDoubleArray(orient,1))
                    fprintf(2,"Invalid data in model parts file: Orientation of PARTICLES.DISK with ID %d.\n",id);
                    fprintf(2,"It must be a numeric value.\n");
                    status = 0; return;
                end
                
                % Radius
                if (length(values) == 5)
                    radius = values(5);
                    if (~this.isDoubleArray(radius,1) || radius <= 0)
                        fprintf(2,"Invalid data in model parts file: Radius of PARTICLES.DISK with ID %d.\n",id);
                        fprintf(2,"It must be a positive value.\n");
                        status = 0; return;
                    end
                end
                
                % Create new particle object
                particle        = Particle_Disk();
                particle.id     = id;
                particle.coord  = coord';
                particle.orient = orient;
                if (length(values) == 5)
                    particle.radius = radius;
                end
                
                % Store handle to particle object
                if (id <= length(drv.particles) && ~isempty(drv.particles(id).id))
                    fprintf(2,"Invalid numbering of particles: IDs cannot be repeated.\n");
                    status = 0; return;
                end
                drv.particles(id) = particle;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of PARTICLES.DISK is incompatible with provided data.\n");
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsLine2D(this,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: WALLS.LINE2D is only allowed in 2D models.\n");
                status = 0; return;
            end
            
            % Total number of line2D walls
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.LINE2D.\n");
                fprintf(2,"It must be a positive integer.\n");
                status = 0; return;
            end
            
            % Update total number of walls
            drv.n_walls = drv.n_walls + n;
            
            % Read each wall
            deblank(fgetl(fid)); % go to next line
            for i = 1:n
                if (feof(fid))
                    break;
                end
                line = deblank(fgetl(fid));
                if (isempty(line) || isnumeric(line))
                    break;
                end
                
                % Read all values of current line
                values = sscanf(line,'%f');
                if (length(values) ~= 5)
                    fprintf(2,"Invalid data in model parts file: Number of parameters of WALLS.LINE2D.\n");
                    fprintf(2,"It requires 5 parameters: ID, coord X1, coord Y1, coord X2, coord Y2.\n");
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of WALLS.LINE2D.\n");
                    fprintf(2,"It must be a positive integer.\n");
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:5);
                if (~this.isDoubleArray(coord,4))
                    fprintf(2,"Invalid data in model parts file: Coordinates of WALLS.LINE2D with ID %d.\n",id);
                    fprintf(2,"It must be two pairs of numeric values: X1,Y1,X2,Y2.\n");
                    status = 0; return;
                end
                
                % Create new wall object
                wall           = Wall_Line2D();
                wall.id        = id;
                wall.coord_ini = coord(1:2)';
                wall.coord_end = coord(3:4)';
                
                % Store handle to wall object
                if (id <= length(drv.walls) && ~isempty(drv.walls(id).id))
                    fprintf(2,"Invalid numbering of walls: IDs cannot be repeated.\n");
                    status = 0; return;
                end
                drv.walls(id) = wall;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.LINE2D is incompatible with provided data.\n");
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsCircle(this,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: WALLS.CIRCLE is only allowed in 2D models.\n");
                status = 0; return;
            end
            
            % Total number of circle walls
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.CIRCLE.\n");
                fprintf(2,"It must be a positive integer.\n");
                status = 0; return;
            end
            
            % Update total number of walls
            drv.n_walls = drv.n_walls + n;
            
            % Read each wall
            deblank(fgetl(fid)); % go to next line
            for i = 1:n
                if (feof(fid))
                    break;
                end
                line = deblank(fgetl(fid));
                if (isempty(line) || isnumeric(line))
                    break;
                end
                
                % Read all values of current line
                values = sscanf(line,'%f');
                if (length(values) ~= 4)
                    fprintf(2,"Invalid data in model parts file: Number of parameters of WALLS.CIRCLE.\n");
                    fprintf(2,"It requires 4 parameters: ID, center coord X, center coord Y, radius.\n");
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of WALLS.CIRCLE.\n");
                    fprintf(2,"It must be a positive integer.\n");
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~this.isDoubleArray(coord,2))
                    fprintf(2,"Invalid data in model parts file: Center coordinates of WALLS.CIRCLE with ID %d.\n",id);
                    fprintf(2,"It must be a pair of numeric values: X,Y.\n");
                    status = 0; return;
                end
                
                % Radius
                radius = values(4);
                if (~this.isDoubleArray(radius,1) || radius <= 0)
                    fprintf(2,"Invalid data in model parts file: Radius of WALLS.CIRCLE with ID %d.\n",id);
                    fprintf(2,"It must be a positive value.\n");
                    status = 0; return;
                end
                
                % Create new wall object
                wall        = Wall_Circle();
                wall.id     = id;
                wall.center = coord';
                wall.radius = radius;
                
                % Store handle to wall object
                if (id <= length(drv.walls) && ~isempty(drv.walls(id).id))
                    fprintf(2,"Invalid numbering of walls: IDs cannot be repeated.\n");
                    status = 0; return;
                end
                drv.walls(id) = wall;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.CIRCLE is incompatible with provided data.\n");
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readModelParts(~,fid,drv)
            status = 1;
            
            % Create ModelPart object
            mp = ModelPart();
            drv.n_mparts = drv.n_mparts + 1;
            drv.mparts(drv.n_mparts) = mp;
            
            % List of reserved names
            reserved = ["PARTICLES","WALLS"];
            
            % Model part name
            line = deblank(fgetl(fid));
            if (isempty(line) || isnumeric(line))
                fprintf(2,"Invalid data in model parts file: NAME of MODELPART was not provided or is invalid.\n");
                status = 0; return;
            end
            line = regexp(line,' ','split');
            if (length(line) ~= 2 || ~strcmp(line{1},'NAME') || ismember(line{2},reserved))
                fprintf(2,"Invalid data in model parts file: NAME of MODELPART was not provided or is invalid.\n");
                status = 0; return;
            end
            mp.name = line{2};
            
            % Model part components
            c = 0;
            while true
                % Get title and total number of components
                line = deblank(fgetl(fid));
                if (isempty(line) || isnumeric(line))
                    break;
                end
                line = regexp(line,' ','split');
                if (~ismember(line{1},reserved))
                    fprintf(2,"Invalid data in model parts file: MODELPART can contain only two fields after its name, PARTICLES and WALLS.\n");
                    status = 0; return;
                elseif (length(line) ~= 2 || isnan(str2double(line{2})) || floor(str2double(line{2})) ~= ceil(str2double(line{2})) || str2double(line{2}) < 0)
                    fprintf(2,"Invalid data in model parts file: Number of %s of MODELPART %s was not provided correctly.\n",line{1},mp.name);
                    status = 0; return;
                end
                
                % PARTICLES
                if (strcmp(line{1},'PARTICLES'))
                    c = c + 1;
                    
                    % Store number of particles
                    np = str2double(line{2});
                    mp.n_particles = np;

                    % Get all particles IDs
                    [particles,count] = fscanf(fid,'%d');
                    if (count ~= np)
                        fprintf(2,"Invalid data in model parts file: Number of PARTICLES of MODELPART %s is not consistent with the provided IDs.\n",mp.name);
                        status = 0; return;
                    end

                    % Store particles IDs
                    mp.id_particles = particles';

                    % Store handle to particle objects
                    for i = 1:np
                        id = particles(i);
                        if (floor(id) ~= ceil(id) || id <=0 || id > length(drv.particles))
                            fprintf(2,"Invalid data in model parts file: PARTICLES IDs of MODELPART %s is not consistent with existing particles.\n",mp.name);
                            status = 0; return;
                        end
                        mp.particles(i) = drv.particles(id);
                    end

                % WALLS
                elseif (strcmp(line{1},'WALLS'))
                    c = c + 1;
                    
                    % Store number of walls
                    nw = str2double(line{2});
                    mp.n_walls = nw;

                    % Get all walls IDs
                    [walls,count] = fscanf(fid,'%d');
                    if (count ~= nw)
                        fprintf(2,"Invalid data in model parts file: Number of WALLS of MODELPART %s is not consistent with the provided IDs.\n",mp.name);
                        status = 0; return;
                    end

                    % Store walls IDs
                    mp.id_walls = walls';

                    % Store handle to walls objects
                    for i = 1:nw
                        id = walls(i);
                        if (floor(id) ~= ceil(id) || id <=0 || id > length(drv.walls))
                            fprintf(2,"Invalid data in model parts file: WALLS IDs of MODELPART %s is not consistent with existing walls.\n",mp.name);
                            status = 0; return;
                        end
                        mp.walls(i) = drv.walls(id);
                    end
                end
                
                if (c == 2 || feof(fid))
                    break;
                end
            end
            
            if (mp.n_particles == 0 && mp.n_walls == 0)
                warning('off','backtrace');
                warning("Model part %s is empty.",mp.name);
                warning('on','backtrace');
            end
        end
        
        %------------------------------------------------------------------
        function status = getSolverParam(this,json,drv)
            status = 1;
            if (~isfield(json,'Solver'))
                fprintf(2,'Missing data in project parameters file: Solver.\n');
                status = 0; return;
            end
            
            % Automatic time step
            if (isfield(json.Solver,'auto_time_step'))
                if (~this.isLogicalArray(json.Solver.auto_time_step,1))
                    fprintf(2,'Invalid data in project parameters file: Solver.auto_time_step.\n');
                    fprintf(2,'It must be a boolean: true or false.\n');
                    status = 0; return;
                end
                drv.auto_step = json.Solver.auto_time_step;
            end
            
            % Time step
            if (isfield(json.Solver,'time_step'))
                if (~this.isDoubleArray(json.Solver.time_step,1) || json.Solver.time_step <= 0)
                    fprintf(2,'Invalid data in project parameters file: Solver.time_step.\n');
                    fprintf(2,'It must be a positive value.\n');
                    status = 0; return;
                end
                drv.time_step = json.Solver.time_step;
            else
                fprintf(2,'Missing data in project parameters file: Solver.time_step.\n');
                status = 0; return;
            end
            
            % Final time
            if (isfield(json.Solver,'final_time'))
                if (~this.isDoubleArray(json.Solver.final_time,1) || json.Solver.final_time <= 0)
                    fprintf(2,'Invalid data in project parameters file: Solver.final_time.\n');
                    fprintf(2,'It must be a positive value.\n');
                    status = 0; return;
                end
                drv.max_time = json.Solver.final_time;
            elseif (~isfield(json.Solver,'max_steps'))
                fprintf(2,'Missing data in project parameters file: Solver.final_time or Solver.max_steps.\n');
                status = 0; return;
            end
            
            % Maximum steps
            if (isfield(json.Solver,'max_steps'))
                if (~this.isIntArray(json.Solver.max_steps,1) || json.Solver.max_steps <= 0)
                    fprintf(2,'Invalid data in project parameters file: Solver.max_steps.\n');
                    fprintf(2,'It must be a positive integer.\n');
                    status = 0; return;
                end
                drv.max_step = json.Solver.max_steps;
            elseif (~isfield(json.Solver,'final_time'))
                fprintf(2,'Missing data in project parameters file: Solver.final_time or Solver.max_steps.\n');
                status = 0; return;
            end
            
            % Time integration scheme: translational velocity
            if ((drv.type == drv.MECHANICAL || drv.type == drv.THERMO_MECHANICAL) && isfield(json.Solver,'integr_scheme_trans'))
                scheme = string(json.Solver.integr_scheme_trans);
                if (~this.isStringArray(scheme,1) || ~strcmp(scheme,'foward_euler'))
                    fprintf(2,'Invalid data in project parameters file: Solver.integr_scheme_trans.\n');
                    fprintf(2,'Available options: foward_euler.\n');
                    status = 0; return;
                end
                if (strcmp(scheme,'foward_euler'))
                    drv.scheme_vtrl = Scheme_FowardEuler();
                end
            end
            
            % Time integration scheme: rotational velocity
            if ((drv.type == drv.MECHANICAL || drv.type == drv.THERMO_MECHANICAL) && isfield(json.Solver,'integr_scheme_rotat'))
                scheme = string(json.Solver.integr_scheme_rotat);
                if (~this.isStringArray(scheme,1) || ~strcmp(scheme,'foward_euler'))
                    fprintf(2,'Invalid data in project parameters file: Solver.integr_scheme_rotat.\n');
                    fprintf(2,'Available options: foward_euler.\n');
                    status = 0; return;
                end
                if (strcmp(scheme,'foward_euler'))
                    drv.scheme_vrot = Scheme_FowardEuler();
                end
            end
            
            % Time integration scheme: temperature
            if ((drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL) && isfield(json.Solver,'integr_scheme_therm'))
                scheme = string(json.Solver.integr_scheme_therm);
                if (~this.isStringArray(scheme,1) || ~strcmp(scheme,'foward_euler'))
                    fprintf(2,'Invalid data in project parameters file: Solver.integr_scheme_therm.\n');
                    fprintf(2,'Available options: foward_euler.\n');
                    status = 0; return;
                end
                if (strcmp(scheme,'foward_euler'))
                    drv.scheme_temp = Scheme_FowardEuler();
                end
            end
            
            % Paralelization
            if (isfield(json.Solver,'parallelization'))
                if (~this.isLogicalArray(json.Solver.parallelization,1))
                    fprintf(2,'Invalid data in project parameters file: Solver.parallelization.\n');
                    fprintf(2,'It must be a boolean: true or false.\n');
                    status = 0; return;
                end
                drv.parallel = json.Solver.parallelization;
            end
            
            % Number of workers
            if (isfield(json.Solver,'workers'))
                if (~this.isIntArray(json.Solver.workers,1) || json.Solver.workers <= 0)
                    fprintf(2,'Invalid data in project parameters file: Solver.workers.\n');
                    fprintf(2,'It must be a positive integer.\n');
                    status = 0; return;
                end
                drv.workers = json.Solver.workers;
            end
        end
        
        %------------------------------------------------------------------
        function status = getBoundingBox(this,json,drv)
            status = 1;
            if (~isfield(json,'BoundingBox'))
                return;
            end
            BB = json.BoundingBox;
            
            % Shape
            if (~isfield(BB,'shape'))
                fprintf(2,'Missing data in project parameters file: BoundingBox.shape.\n');
                fprintf(2,'Available options: rectangle, circle.\n');
                status = 0; return;
            end
            shape = string(BB.shape);
            if (~this.isStringArray(shape,1))
                fprintf(2,'Invalid data in project parameters file: BoundingBox.shape.\n');
                status = 0; return;
            end
            
            % RECTANGLE
            if (strcmp(shape,'rectangle'))
                warn = 0;
                
                % Minimum limits
                if (isfield(BB,'limit_min'))
                    limit_min = BB.limit_min;
                    if (~this.isDoubleArray(limit_min,2))
                        fprintf(2,'Invalid data in project parameters file: BoundingBox.limit_min.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y coordinates of bottom-left corner.\n');
                        status = 0; return;
                    end
                else
                    limit_min = [-inf;-inf];
                    warn = warn + 1;
                end
                
                % Maximum limits
                if (isfield(BB,'limit_max'))
                    limit_max = BB.limit_max;
                    if (~this.isDoubleArray(limit_max,2))
                        fprintf(2,'Invalid data in project parameters file: BoundingBox.limit_max.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y coordinates of top-right corner.\n');
                        status = 0; return;
                    end
                else
                    limit_max = [inf;inf];
                    warn = warn + 2;
                end
                
                % Check consistency
                warning('off','backtrace');
                if (warn == 1)
                    warning("Minimum limits of bounding box were not provided. Infinite limits were assumed.");
                elseif (warn == 2)
                    warning("Maximum limits of bounding box were not provided. Infinite limits were assumed.");
                elseif (warn == 3)
                    warning("Maximum and minimum limits of bounding box were not provided. Bounding box will not be considered.");
                    return;
                end
                if (limit_min(1) >= limit_max(1) || limit_min(2) >= limit_max(2))
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.limit_min or BoundingBox.limit_max.\n');
                    fprintf(2,'Minimum coordinates must be smaller than the maximum ones.\n');
                    status = 0;
                    return;
                end
                warning('on','backtrace');
                
                % Create object and set properties
                bbox = BBox_Rectangle();
                bbox.limit_min = limit_min';
                bbox.limit_max = limit_max';
                drv.bbox = bbox;
                
            % CIRCLE
            elseif (strcmp(shape,'circle'))
                if (~isfield(BB,'center') || ~isfield(BB,'radius'))
                    fprintf(2,'Invalid data in project parameters file: Missing BoundingBox.center and/or BoundingBox.radius.\n');
                    status = 0; return;
                end
                center = BB.center;
                radius = BB.radius;
                
                % Center
                if (~this.isDoubleArray(center,2))
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.center.\n');
                    fprintf(2,'It must be a pair of numeric values with X,Y coordinates of center point.\n');
                    status = 0; return;
                end
                
                % Radius
                if (~this.isDoubleArray(radius,1) || radius <= 0)
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.radius.\n');
                    fprintf(2,'It must be a positive value.\n');
                    status = 0; return;
                end
                
                % Create object and set properties
                bbox = BBox_Circle();
                bbox.center = center';
                bbox.radius = radius;
                drv.bbox = bbox;
                
            else
                fprintf(2,'Invalid data in project parameters file: BoundingBox.shape.\n');
                fprintf(2,'Available options: rectangle, circle.\n');
                status = 0; return;
            end
            
            % Interval
            if (isfield(BB,'interval'))
                interval = BB.interval;
                if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.interval.\n');
                    fprintf(2,'It must be a pair of numeric values and the minimum value must be smaller than the maximum.\n');
                    status = 0; return;
                end
                drv.bbox.interval = interval';
            end
        end
        
        %------------------------------------------------------------------
        function status = getGlobalCondition(this,json,drv)
            status = 1;
            if (~isfield(json,'GlobalCondition'))
                return;
            end
            GC = json.GlobalCondition;
            
            % Gravity
            if (isfield(GC,'gravity'))
                g = GC.gravity;
                if (~this.isDoubleArray(g,2))
                    fprintf(2,'Invalid data in project parameters file: GlobalCondition.gravity.\n');
                    fprintf(2,'It must be a pair of numeric values with X,Y gravity acceleration components.\n');
                    status = 0; return;
                end
                drv.gravity = g';
            end
        end
        
        %------------------------------------------------------------------
        function status = getInitialCondition(this,json,drv)
            status = 1;
            if (~isfield(json,'InitialCondition'))
                return;
            end
            IC = json.InitialCondition;
            
            % TRANSLATIONAL VELOCITY
            if (isfield(IC,'TranslationalVelocity'))
                TranslationalVelocity = IC.TranslationalVelocity;
                
                for i = 1:length(TranslationalVelocity)
                    TV = TranslationalVelocity(i);
                    if (~isfield(TV,'value') || ~isfield(TV,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: InitialCondition.TranslationalVelocity must have value and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Velocity value
                    vel = TV.value;
                    if (~this.isDoubleArray(vel,2))
                        fprintf(2,'Invalid data in project parameters file: InitialCondition.TranslationalVelocity.value.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y velocity components.\n');
                        status = 0; return;
                    end
                    
                    % Apply initial velocity to selected particles
                    model_parts = string(TV.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            fprintf(2,'Invalid data in project parameters file: InitialCondition.TranslationalVelocity.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            for k = 1:drv.n_particles
                                drv.particles(k).veloc_trl = vel';
                            end
                        else
                            mp = [];
                            for k = 1:drv.n_mparts
                                if (strcmp(drv.mparts(k).name,name))
                                    mp = drv.mparts(k);
                                end
                            end
                            if (isempty(mp))
                                warning('off','backtrace');
                                warning("Model part %s used in InitialCondition.TranslationalVelocity does not exist.",name);
                                warning('on','backtrace');
                                continue;
                            end
                            for k = 1:mp.n_particles
                                mp.particles(k).veloc_trl = vel';
                            end
                        end
                    end
                end
            end
            
            % ROTATIONAL VELOCITY
            if (isfield(IC,'RotationalVelocity'))
                RotationalVelocity = IC.RotationalVelocity;
                
                for i = 1:length(RotationalVelocity)
                    RV = RotationalVelocity(i);
                    if (~isfield(RV,'value') || ~isfield(RV,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: InitialCondition.RotationalVelocity must have value and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Velocity value
                    vel = RV.value;
                    if (~this.isDoubleArray(vel,1))
                        fprintf(2,'Invalid data in project parameters file: InitialCondition.RotationalVelocity.value.\n');
                        fprintf(2,'It must be a numeric value with rotational velocity.\n');
                        status = 0; return;
                    end
                    
                    % Apply initial velocity to selected particles
                    model_parts = string(RV.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            fprintf(2,'Invalid data in project parameters file: InitialCondition.RotationalVelocity.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            for k = 1:drv.n_particles
                                drv.particles(k).veloc_rot = vel;
                            end
                        else
                            mp = [];
                            for k = 1:drv.n_mparts
                                if (strcmp(drv.mparts(k).name,name))
                                    mp = drv.mparts(k);
                                end
                            end
                            if (isempty(mp))
                                warning('off','backtrace');
                                warning("Model part %s used in InitialCondition.RotationalVelocity does not exist.",name);
                                warning('on','backtrace');
                                continue;
                            end
                            for k = 1:mp.n_particles
                                mp.particles(k).veloc_rot = vel;
                            end
                        end
                    end
                end
            end
            
            % TEMPERATURE
            if (isfield(IC,'Temperature'))
                Temperature = IC.Temperature;
                
                for i = 1:length(Temperature)
                    T = Temperature(i);
                    if (~isfield(T,'value') || ~isfield(T,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: InitialCondition.Temperature must have value and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Temperature value
                    temp = T.value;
                    if (~this.isDoubleArray(temp,1))
                        fprintf(2,'Invalid data in project parameters file: InitialCondition.Temperature.value.\n');
                        fprintf(2,'It must be a numeric value with temperature.\n');
                        status = 0; return;
                    end
                    
                    % Apply initial temperature to selected particles
                    model_parts = string(T.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            fprintf(2,'Invalid data in project parameters file: InitialCondition.Temperature.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            for k = 1:drv.n_particles
                                drv.particles(k).temperature = temp;
                            end
                        else
                            mp = [];
                            for k = 1:drv.n_mparts
                                if (strcmp(drv.mparts(k).name,name))
                                    mp = drv.mparts(k);
                                end
                            end
                            if (isempty(mp))
                                warning('off','backtrace');
                                warning("Model part %s used in InitialCondition.Temperature does not exist.",name);
                                warning('on','backtrace');
                                continue;
                            end
                            for k = 1:mp.n_particles
                                mp.particles(k).temperature = temp;
                            end
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getMaterial(this,json,drv)
            status = 1;
            if (~isfield(json,'Material'))
                fprintf(2,'Missing data in project parameters file: Material.\n');
                status = 0; return;
            end
            
            for i = 1:length(json.Material)
                M = json.Material(i);
                if (~isfield(M,'name') || ~isfield(M,'model_parts') || ~isfield(M,'properties'))
                    fprintf(2,'Missing data in project parameters file: Material must have name, model_parts and properties.\n');
                    status = 0; return;
                end
                
                % Create material object
                mat = Material();
                drv.n_materials = drv.n_materials + 1;
                drv.materials = mat;
                
                % Name
                name = string(M.name);
                if (~this.isStringArray(name,1))
                    fprintf(2,'Invalid data in project parameters file: Material.name.\n');
                    fprintf(2,'It must be a string with the name representing the material.\n');
                    status = 0; return;
                end
                mat.name = name;
                
                % Properties
                prop = M.properties;
                msg = 0; % controler for type of message
                
                if (isfield(prop,'density'))
                    if (~this.isDoubleArray(prop.density,1))
                        msg = -100;
                    elseif (prop.density <= 0)
                        msg = msg + 1;
                    end
                    mat.density = prop.density;
                end
                if (isfield(prop,'young_modulus'))
                    if (~this.isDoubleArray(prop.young_modulus,1))
                        msg = -100;
                    elseif (prop.young_modulus <= 0)
                        msg = msg + 1;
                    end
                    mat.young = prop.young_modulus;
                end
                if (isfield(prop,'young_modulus_real'))
                    if (~this.isDoubleArray(prop.young_modulus_real,1))
                        msg = -100;
                    elseif (prop.young_modulus_real <= 0)
                        msg = msg + 1;
                    end
                    mat.young_real = prop.young_modulus_real;
                end
                if (isfield(prop,'shear_modulus'))
                    if (~this.isDoubleArray(prop.shear_modulus,1))
                        msg = -100;
                    elseif (prop.shear_modulus <= 0)
                        msg = msg + 1;
                    end
                    mat.shear = prop.shear_modulus;
                end
                if (isfield(prop,'poisson_ratio'))
                    if (~this.isDoubleArray(prop.poisson_ratio,1))
                        msg = -100;
                    elseif (prop.poisson_ratio < 0 || prop.poisson_ratio > 0.5)
                        msg = msg + 1;
                    end
                    mat.poisson = prop.poisson_ratio;
                end
                if (isfield(prop,'restitution_coeff'))
                    if (~this.isDoubleArray(prop.restitution_coeff,1))
                        msg = -100;
                    elseif (prop.restitution_coeff < 0 || prop.restitution_coeff > 1)
                        msg = msg + 1;
                    end
                    mat.restitution = prop.restitution_coeff;
                end
                if (isfield(prop,'thermal_conductivity'))
                    if (~this.isDoubleArray(prop.thermal_conductivity,1))
                        msg = -100;
                    elseif (prop.thermal_conductivity <= 0)
                        msg = msg + 1;
                    end
                    mat.conduct = prop.thermal_conductivity;
                end
                if (isfield(prop,'heat_capacity'))
                    if (~this.isDoubleArray(prop.heat_capacity,1))
                        msg = -100;
                    elseif (prop.heat_capacity <= 0)
                        msg = msg + 1;
                    end
                    mat.capacity = prop.heat_capacity;
                end
                if (isfield(prop,'thermal_expansion'))
                    if (~this.isDoubleArray(prop.thermal_expansion,1))
                        msg = -100;
                    elseif (prop.thermal_expansion <= 0)
                        msg = msg + 1;
                    end
                    mat.expansion = prop.thermal_expansion;
                end
                
                if (msg < 0)
                    fprintf(2,'Invalid data in project parameters file: Material.properties.\n');
                    fprintf(2,'Properties must be numerical values.\n');
                    status = 0; return;
                elseif(msg > 0)
                    warning('off','backtrace');
                    warning("Unphysical property value was found for material %s.",mat.name);
                    warning('on','backtrace');
                end
                
                % Set material to selected model parts
                model_parts = string(M.model_parts);
                for j = 1:length(model_parts)
                    mp_name = model_parts(j);
                    if (~this.isStringArray(mp_name,1))
                        fprintf(2,'Invalid data in project parameters file: Material.model_parts.\n');
                        fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                        status = 0; return;
                    elseif (strcmp(mp_name,'PARTICLES'))
                        for k = 1:drv.n_particles
                            drv.particles(k).material = mat;
                        end
                    elseif (strcmp(mp_name,'WALLS'))
                        for k = 1:drv.n_walls
                            drv.walls(k).material = mat;
                        end
                    else
                        mp = [];
                        for k = 1:drv.n_mparts
                            if (strcmp(drv.mparts(k).name,mp_name))
                                mp = drv.mparts(k);
                            end
                        end
                        if (isempty(mp))
                            warning('off','backtrace');
                            warning("Model part %s used in Material %s does not exist.",mp_name,mat.name);
                            warning('on','backtrace');
                            continue;
                        end
                        for k = 1:mp.n_particles
                            mp.particles(k).material = mat;
                        end
                    end
                end
            end
            
            if (drv.n_materials == 0)
                fprintf(2,'Invalid data in project parameters file: No valid material was found.\n');
                status = 0; return;
            end
        end
    end
    
    %% Static methods
    methods (Static)
        %------------------------------------------------------------------
        function is = isLogicalArray(variable,size)
            if (isempty(variable) || length(variable) ~= size || ~isa(variable,'logical'))
                is = false;
            else
                is = true;
            end
        end
        
        %------------------------------------------------------------------
        function is = isIntArray(variable,size)
            if (isempty(variable) || length(variable) ~= size || ~isnumeric(variable) || ~isa(variable,'double') || floor(variable) ~= ceil(variable))
                is = false;
            else
                is = true;
            end
        end
        
        %------------------------------------------------------------------
        function is = isDoubleArray(variable,size)
            if (isempty(variable) || length(variable) ~= size || ~isnumeric(variable) || ~isa(variable,'double'))
                is = false;
            else
                is = true;
            end
        end
        
        %------------------------------------------------------------------
        function is = isStringArray(variable,size)
            if (isempty(variable) || length(variable) ~= size || (~isa(variable,'string') && ~isa(variable,'char')))
                is = false;
            else
                is = true;
            end
        end
    end
end