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
            json_txt = char(fread(fid,inf)');
            fclose(fid);
            if (isempty(json_txt))
                fprintf(2,'Empty project parameters file.\n');
                status = 0;
                return;
            end
            json = jsondecode(json_txt);
            
            % Feed simulation data
            if (status)
                [status,drv,model_parts_file] = this.getProblemData(json);
            end
            if (status)
                status = this.getModelParts(drv,path,model_parts_file);
            end
            if (status)
                status = this.getBoundingBox(json,drv);
            end
            if (status)
                status = this.getInitialCondition(json,drv);
            end
            
            % Final checks:
            % All particles have geometric property (radius for disk).
        end
        
        %------------------------------------------------------------------
        function [status,drv,model_parts_file] = getProblemData(~,json)
            status = 1;
            drv = [];
            model_parts_file = [];
            
            % Check if all fields exist
            if (~isfield(json,'ProblemData'))
                fprintf(2,'Missing data in project parameters file: ProblemData.\n');
                status = 0;
                return;
            end
            PD = json.ProblemData;
            
            if (~isfield(PD,'name'))
                fprintf(2,'Missing data in project parameters file: ProblemData.name.\n');
                status = 0;
                return;
            elseif (~isfield(PD,'analysis_type'))
                fprintf(2,'Missing data in project parameters file: ProblemData.analysis_type.\n');
                status = 0;
                return;
            elseif (~isfield(PD,'dimension'))
                fprintf(2,'Missing data in project parameters file: ProblemData.dimension.\n');
                status = 0;
                return;
            elseif (~isfield(PD,'model_parts_file'))
                fprintf(2,'Missing data in project parameters file: ProblemData.model_parts_file.\n');
                status = 0;
                return;
            end
            
            % Create object of Driver class
            analysis_type = string(PD.analysis_type);
            if (strcmp(analysis_type,'mechanical'))
                drv = Driver_Mechanical();
            elseif (strcmp(analysis_type,'thermal'))
                drv = Driver_Thermal();
            elseif (strcmp(analysis_type,'thermo_mechanical'))
                drv = Driver_ThermoMechanical();
            else
                fprintf(2,'Invalid data in project parameters file: ProblemData.analysis_type.\n');
                fprintf(2,'Available options: mechanical, thermal, thermo_mechanical.\n');
                status = 0;
                return;
            end
            
            % Set problem name
            drv.name = string(PD.name);
            
            % Set model dimension
            dim = PD.dimension;
            if (~isnumeric(dim) || ~isa(dim,'double') || (dim ~= 2 && dim ~= 3))
                fprintf(2,'Invalid data in project parameters file: ProblemData.dimension.\n');
                fprintf(2,'Available options: 2 or 3.\n');
                status = 0;
                return;
            end
            drv.dimension = dim;
            
            % Get model parts file name
            model_parts_file = string(PD.model_parts_file);
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
                status = 0;
                return;
            end
            
            % Set class of vectors with default sub-classes
            drv.particles = Particle_Disk();
            drv.walls     = Wall_Line2D();
            drv.mparts    = ModelPart();
            
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
            
            % Check input data
            if (drv.n_particles == 0)
                fprintf(2,"The must have at least one particle.\n");
                status = 0;
                return;
            else
                ids = zeros(drv.n_particles,1);
                for i = 1:drv.n_particles
                    id = drv.particles(i).id;
                    if (any(ids==id))
                        fprintf(2,"Invalid numbering of particles: IDs cannot be repeated.\n");
                        status = 0;
                        return;
                    end
                    ids(i) = id;
                end
                if (drv.n_particles ~= max(ids))
                    fprintf(2,"Invalid numbering of particles: IDs cannot skip numbers.\n");
                    status = 0;
                    return;
                end
            end
            
            if (drv.n_walls == 0)
                drv.walls = [];
            else
                ids = zeros(drv.n_walls,1);
                for i = 1:drv.n_walls
                    id = drv.walls(i).id;
                    if (any(ids==id))
                        fprintf(2,"Invalid numbering of walls: IDs cannot be repeated.\n");
                        status = 0;
                        return;
                    end
                    ids(i) = id;
                end
                if (drv.n_walls ~= max(ids))
                    fprintf(2,"Invalid numbering of walls: IDs cannot skip numbers.\n");
                    status = 0;
                    return;
                end
            end
            
            if (drv.n_mparts == 0)
                drv.mparts = [];
            end
        end
        
        %------------------------------------------------------------------
        function status = readParticlesDisk(~,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: PARTICLES.DISK is only allowed in 2D models.\n");
                status = 0;
                return;
            end
            
            % Total number of disk particles
            n = fscanf(fid,'%d',1);
            if (isempty(n) || ~isnumeric(n) || floor(n) ~= ceil(n) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of PARTICLES.DISK.\n");
                fprintf(2,"It must be a positive integer.\n");
                status = 0;
                return;
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
                    fprintf(2,"Invalid data in model parts file: Number of PARTICLES.DISK parameters.\n");
                    fprintf(2,"PARTICLES.DISK requires 5 parameters: ID, coord X, coord Y, orientation, radius (radius is optional in this file).\n");
                    status = 0;
                    return;
                end
                
                % ID number
                id = values(1);
                if (~isnumeric(id) || floor(id) ~= ceil(id) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of PARTICLES.DISK.\n");
                    fprintf(2,"It must be a positive integer.\n");
                    status = 0;
                    return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~isnumeric(coord) || ~isa(coord,'double'))
                    fprintf(2,"Invalid data in model parts file: Coordinates of PARTICLES.DISK with ID %d.\n",id);
                    fprintf(2,"It must be a pair of numeric values.\n");
                    status = 0;
                    return;
                end
                
                % Orientation angle
                orient = values(4);
                if (~isnumeric(orient) || ~isa(orient,'double'))
                    fprintf(2,"Invalid data in model parts file: Orientation of PARTICLES.DISK with ID %d.\n",id);
                    fprintf(2,"It must be a numeric value.\n");
                    status = 0;
                    return;
                end
                
                % Radius
                if (length(values) == 5)
                    radius = values(5);
                    if (~isnumeric(radius) || ~isa(radius,'double') || radius <= 0)
                        fprintf(2,"Invalid data in model parts file: Radius of PARTICLES.DISK with ID %d.\n",id);
                        fprintf(2,"It must be a positive value.\n");
                        status = 0;
                        return;
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
                drv.particles(id) = particle;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of PARTICLES.DISK is incompatible with provided data.\n");
                status = 0;
                return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsLine2D(~,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: WALLS.LINE2D is only allowed in 2D models.\n");
                status = 0;
                return;
            end
            
            % Total number of line2D walls
            n = fscanf(fid,'%d',1);
            if (isempty(n) || ~isnumeric(n) || floor(n) ~= ceil(n) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.LINE2D.\n");
                fprintf(2,"It must be a positive integer.\n");
                status = 0;
                return;
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
                    fprintf(2,"Invalid data in model parts file: Number of WALLS.LINE2D parameters.\n");
                    fprintf(2,"WALLS.LINE2D requires 5 parameters: ID, coord X1, coord Y1, coord X2, coord Y2.\n");
                    status = 0;
                    return;
                end
                
                % ID number
                id = values(1);
                if (~isnumeric(id) || floor(id) ~= ceil(id) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of WALLS.LINE2D.\n");
                    fprintf(2,"It must be a positive integer.\n");
                    status = 0;
                    return;
                end
                
                % Coordinates
                coord = values(2:5);
                if (~isnumeric(coord) || ~isa(coord,'double'))
                    fprintf(2,"Invalid data in model parts file: Coordinates of WALLS.LINE2D with ID %d.\n",id);
                    fprintf(2,"It must be two pairs of numeric values: X1,Y1,X2,Y2.\n");
                    status = 0;
                    return;
                end
                
                % Create new wall object
                wall           = Wall_Line2D();
                wall.id        = id;
                wall.coord_ini = coord(1:2)';
                wall.coord_end = coord(3:4)';
                
                % Store handle to wall object
                drv.walls(id) = wall;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.LINE2D is incompatible with provided data.\n");
                status = 0;
                return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsCircle(~,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: WALLS.CIRCLE is only allowed in 2D models.\n");
                status = 0;
                return;
            end
            
            % Total number of circle walls
            n = fscanf(fid,'%d',1);
            if (isempty(n) || ~isnumeric(n) || floor(n) ~= ceil(n) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.CIRCLE.\n");
                fprintf(2,"It must be a positive integer.\n");
                status = 0;
                return;
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
                    fprintf(2,"Invalid data in model parts file: Number of WALLS.CIRCLE parameters.\n");
                    fprintf(2,"WALLS.CIRCLE requires 4 parameters: ID, center coord X, center coord Y, radius.\n");
                    status = 0;
                    return;
                end
                
                % ID number
                id = values(1);
                if (~isnumeric(id) || floor(id) ~= ceil(id) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of WALLS.CIRCLE.\n");
                    fprintf(2,"It must be a positive integer.\n");
                    status = 0;
                    return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~isnumeric(coord) || ~isa(coord,'double'))
                    fprintf(2,"Invalid data in model parts file: Center coordinates of WALLS.CIRCLE with ID %d.\n",id);
                    fprintf(2,"It must be a pair of numeric values: X,Y.\n");
                    status = 0;
                    return;
                end
                
                % Radius
                radius = values(4);
                if (~isnumeric(radius) || ~isa(radius,'double') || radius <= 0)
                    fprintf(2,"Invalid data in model parts file: Radius of WALLS.CIRCLE with ID %d.\n",id);
                    fprintf(2,"It must be a positive value.\n");
                    status = 0;
                    return;
                end
                
                % Create new wall object
                wall        = Wall_Circle();
                wall.id     = id;
                wall.center = coord';
                wall.radius = radius;
                
                % Store handle to wall object
                drv.walls(id) = wall;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.CIRCLE is incompatible with provided data.\n");
                status = 0;
                return;
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
                status = 0;
                return;
            end
            line = regexp(line,' ','split');
            if (length(line) ~= 2 || ~strcmp(line{1},'NAME') || ismember(line{2},reserved))
                fprintf(2,"Invalid data in model parts file: NAME of MODELPART was not provided or is invalid.\n");
                status = 0;
                return;
            end
            mp.name = line{2};
            
            % Model part components
            line = deblank(fgetl(fid));
            if (isempty(line) || isnumeric(line))
                warning('off','backtrace');
                warning("Model part %s is empty.",mp.name);
                warning('on','backtrace');
                return;
            end
            line = regexp(line,' ','split');
            if (~ismember(line{1},reserved))
                fprintf(2,"Invalid data in model parts file: MODELPART can contain only two fields after its name, PARTICLES and WALLS.\n");
                status = 0;
                return;
            elseif (length(line) ~= 2 || isnan(str2double(line{2})) || floor(str2double(line{2})) ~= ceil(str2double(line{2})) || str2double(line{2}) < 0)
                fprintf(2,"Invalid data in model parts file: Number of %s of MODELPART %s was not provided correctly.\n",line{1},mp.name);
                status = 0;
                return;
            end
            
            % PARTICLES
            if (strcmp(line{1},'PARTICLES'))
                % Store number of particles
                np = str2double(line{2});
                mp.n_particles = np;
                
                % Get all particles IDs
                [particles,count] = fscanf(fid,'%d');
                if (count ~= np)
                    fprintf(2,"Invalid data in model parts file: Number of PARTICLES of MODELPART %s is not consistent with the provided IDs.\n",mp.name);
                    status = 0;
                    return;
                end
                
                % Store particles IDs
                mp.id_particles = particles';
                
                % Store handle to particle objects
                if (np > 0)
                    mp.particles = Particle_Disk();
                    for i = 1:np
                        id = particles(i);
                        if (floor(id) ~= ceil(id) || id <=0 || id > length(drv.particles))
                            fprintf(2,"Invalid data in model parts file: PARTICLES IDs of MODELPART %s is not consistent with existing particles.\n",mp.name);
                            status = 0;
                            return;
                        end
                        mp.particles(i) = drv.particles(id);
                    end
                end
            end
            if (feof(fid))
                return;
            end
            
            % WALLS
            line = deblank(fgetl(fid));
            if (isempty(line) || isnumeric(line))
                return;
            end
            line = regexp(line,' ','split');
            if (~ismember(line{1},reserved))
                fprintf(2,"Invalid data in model parts file: MODELPART can contain only two fields after its name, PARTICLES and WALLS.\n");
                status = 0;
                return;
            elseif (length(line) ~= 2 || isnan(str2double(line{2})) || floor(str2double(line{2})) ~= ceil(str2double(line{2})) || str2double(line{2}) < 0)
                fprintf(2,"Invalid data in model parts file: Number of %s of MODELPART %s was not provided correctly.\n",line{1},mp.name);
                status = 0;
                return;
            end
            
            if (strcmp(line{1},'WALLS'))
                % Store number of walls
                nw = str2double(line{2});
                mp.n_walls = nw;
                
                % Get all walls IDs
                [walls,count] = fscanf(fid,'%d');
                if (count ~= nw)
                    fprintf(2,"Invalid data in model parts file: Number of WALLS of MODELPART %s is not consistent with the provided IDs.\n",mp.name);
                    status = 0;
                    return;
                end
                
                % Store walls IDs
                mp.id_walls = walls';
                
                % Store handle to walls objects
                if (nw > 0)
                    mp.walls = Wall_Line2D();
                    for i = 1:nw
                        id = walls(i);
                        if (floor(id) ~= ceil(id) || id <=0 || id > length(drv.walls))
                            fprintf(2,"Invalid data in model parts file: WALLS IDs of MODELPART %s is not consistent with existing walls.\n",mp.name);
                            status = 0;
                            return;
                        end
                        mp.walls(i) = drv.walls(id);
                    end
                end
            end
            
            if (mp.n_particles == 0 && mp.n_walls == 0)
                warning('off','backtrace');
                warning("Model part %s is empty.",mp.name);
                warning('on','backtrace');
            end
        end
        
        %------------------------------------------------------------------
        function status = getBoundingBox(~,json,drv)
            status = 1;
            if (~isfield(json,'BoundingBox'))
                return;
            end
            BoundingBox = json.BoundingBox;
            
            % Shape
            if (~isfield(BoundingBox,'shape'))
                fprintf(2,'Missing data in project parameters file: BoundingBox.shape.\n');
                fprintf(2,'Available options: rectangle, circle.\n');
                status = 0;
                return;
            end
            shape = string(BoundingBox.shape);
            
            % Rectangle
            if (strcmp(shape,'rectangle'))
                warn = 0;
                
                % Minimum limits
                if (isfield(BoundingBox,'limit_min'))
                    limit_min = BoundingBox.limit_min;
                    if (length(limit_min) ~= 2 || ~isnumeric(limit_min))
                        fprintf(2,'Invalid data in project parameters file: BoundingBox.limit_min.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y coordinates of bottom-left corner.\n');
                        status = 0;
                        return;
                    end
                else
                    limit_min = [-inf;-inf];
                    warn = warn + 1;
                end
                
                % Maximum limits
                if (isfield(BoundingBox,'limit_max'))
                    limit_max = BoundingBox.limit_max;
                    if (length(limit_max) ~= 2 || ~isnumeric(limit_max))
                        fprintf(2,'Invalid data in project parameters file: BoundingBox.limit_max.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y coordinates of top-right corner.\n');
                        status = 0;
                        return;
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
                
            % Circle
            elseif (strcmp(shape,'circle'))
                if (~isfield(BoundingBox,'center') || ~isfield(BoundingBox,'radius'))
                    fprintf(2,'Invalid data in project parameters file: Missing BoundingBox.center and/or BoundingBox.radius.\n');
                    status = 0;
                    return;
                end
                center = BoundingBox.center;
                radius = BoundingBox.radius;
                
                % Center
                if (length(center) ~= 2 || ~isnumeric(center))
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.center.\n');
                    fprintf(2,'It must be a pair of numeric values with X,Y coordinates of center point.\n');
                    status = 0;
                    return;
                end
                
                % Radius
                if (~isnumeric(radius) || radius <= 0)
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.radius.\n');
                    fprintf(2,'It must be a positive value.\n');
                    status = 0;
                    return;
                end
                
                % Create object and set properties
                bbox = BBox_Circle();
                bbox.center = center';
                bbox.radius = radius;
                drv.bbox = bbox;
                
            % Polygon
%             elseif (strcmp(BoundingBox.shape,'polygon'))
%                 if (~isfield(BoundingBox,'coord_x') || ~isfield(BoundingBox,'coord_y'))
%                     fprintf(2,'Invalid data in project parameters file: Missing X or Y coordinates of BoundingBox with polygon shape.\n');
%                     status = 0;
%                     return;
%                 end
%                 coord_x = BoundingBox.coord_x;
%                 coord_y = BoundingBox.coord_y;
%                 
%                 % Check consistency
%                 if (~isnumeric(coord_x) || ~isnumeric(coord_y) || length(coord_x) ~= length(coord_y))
%                     fprintf(2,'Invalid data in project parameters file: BoundingBox.coord_x and BoundingBox.coord_y must be numeric vectors of same size.\n');
%                     status = 0;
%                     return;
%                 end
%                 
%                 % Check if polygon is valid
%                 
%                 
%                 % Create object and set properties
%                 bbox = BBox_Polygon();
%                 bbox.coord_x = coord_x;
%                 bbox.coord_y = coord_y;
%                 drv.bbox = bbox;
            else
                fprintf(2,'Invalid data in project parameters file: BoundingBox.shape.\n');
                fprintf(2,'Available options: rectangle, circle.\n');
                status = 0;
                return;
            end
            
            % Interval
            if (isfield(BoundingBox,'interval'))
                interval = BoundingBox.interval;
                if (length(interval) ~= 2 || ~isnumeric(interval) || interval(1) >= interval(2))
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.interval.\n');
                    fprintf(2,'It must be a pair of numeric values and the minimum value must be smaller than the maximum.\n');
                    status = 0;
                    return;
                end
                drv.bbox.interval = interval';
            end
        end
        
        %------------------------------------------------------------------
        function status = getInitialCondition(~,json,drv)
            status = 1;
            if (~isfield(json,'InitialCondition'))
                return;
            end
            InitialCondition = json.InitialCondition;
            
            % Translational velocity
            if (isfield(InitialCondition,'TranslationalVelocity'))
                TranslationalVelocity = InitialCondition.TranslationalVelocity;
                
                for i = 1:length(TranslationalVelocity)
                    TV = TranslationalVelocity(i);
                    if (~isfield(TV,'value') || ~isfield(TV,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: InitialCondition.TranslationalVelocity.value or InitialCondition.model_parts.\n');
                        status = 0;
                        return;
                    end
                    
                    % Velocity value
                    vel = TV.value;
                    if (length(vel) ~= 2 || ~isnumeric(vel))
                        fprintf(2,'Invalid data in project parameters file: InitialCondition.TranslationalVelocity.value.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y velocity components.\n');
                        status = 0;
                        return;
                    end
                    
                    % Apply initial velocity to selected particles
                    model_parts = TV.model_parts;
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~isa(name,'string'))
                            fprintf(2,'Invalid data in project parameters file: InitialCondition.TranslationalVelocity.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0;
                            return;
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
                                % warning
                                continue;
                            end
                            for k = 1:mp.n_particles
                                mp.particles(k).veloc_trl = vel';
                            end
                        end
                    end
                end
            end
        end
    end
end
