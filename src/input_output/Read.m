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
                fprintf(2,'Error: empty project parameters file.\n\n');
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
            
            % Final checks:
            % At least 1 particle;
            % Repeated IDs of particles and walls.
            % Gap in the IDs numbering.
            % All particles have geometric property (radius for disk)
        end
        
        %------------------------------------------------------------------
        function [status,drv,model_parts_file] = getProblemData(~,json)
            status = 1;
            drv = [];
            model_parts_file = [];
            
            % Check if all fields exist
            if (~isfield(json,'ProblemData'))
                fprintf(2,'Missing data in project parameters file: ProblemData.\n\n');
                status = 0;
                return;
            end
            
            ProblemData = json.ProblemData;
            
            if (~isfield(ProblemData,'name'))
                fprintf(2,'Missing data in project parameters file: ProblemData.name.\n\n');
                status = 0;
                return;
            elseif (~isfield(ProblemData,'analysis_type'))
                fprintf(2,'Missing data in project parameters file: ProblemData.analysis_type.\n\n');
                status = 0;
                return;
            elseif (~isfield(ProblemData,'dimension'))
                fprintf(2,'Missing data in project parameters file: ProblemData.dimension.\n\n');
                status = 0;
                return;
            elseif (~isfield(ProblemData,'model_parts_file'))
                fprintf(2,'Missing data in project parameters file: ProblemData.model_parts_file.\n\n');
                status = 0;
                return;
            end
            
            % Create object of Driver class
            analysis_type = string(ProblemData.analysis_type);
            if (strcmp(analysis_type,'mechanical'))
                drv = Driver_Mechanical();
            elseif (strcmp(analysis_type,'thermal'))
                drv = Driver_Thermal();
            elseif (strcmp(analysis_type,'thermo_mechanical'))
                drv = Driver_ThermoMechanical();
            else
                fprintf(2,'Invalid data in project parameters file: ProblemData.analysis_type.\n');
                fprintf(2,'Available options: mechanical, thermal, thermo_mechanical.\n\n');
                status = 0;
                return;
            end
            
            % Set problem name
            drv.name = string(ProblemData.name);
            
            % Set model dimension
            dim = ProblemData.dimension;
            if (~isnumeric(dim) || ~isa(dim,'double') || (dim ~= 2 && dim ~= 3))
                fprintf(2,'Invalid data in project parameters file: ProblemData.dimension.\n');
                fprintf(2,'Available options: 2 or 3.\n\n');
                status = 0;
                return;
            end
            drv.dimension = dim;
            
            % Get model parts file name
            model_parts_file = string(ProblemData.model_parts_file);
        end
        
        %------------------------------------------------------------------
        function status = getModelParts(this,drv,path,file)
            status = 1;
            
            % Open model parts file
            fullname = fullfile(path,file);
            fid = fopen(fullname,'rt');
            if (fid < 0)
                fprintf(2,"Error opening model parts file: %s\n", file);
                fprintf(2,"It must have the same path of the project parameters file.\n\n");
                status = 0;
                return;
            end
            
            % Set class of vectors
            drv.particles = Particle();
            drv.walls     = Wall();
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
        end
        
        %------------------------------------------------------------------
        function status = readParticlesDisk(~,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: PARTICLES.DISK is only allowed in 2D models.\n\n");
                status = 0;
                return;
            end
            
            % Total number of disk particles
            n = fscanf(fid,'%d',1);
            if (isempty(n) || ~isnumeric(n) || floor(n) ~= ceil(n) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of PARTICLES.DISK.\n");
                fprintf(2,"It must be a positive integer.\n\n");
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
                    fprintf(2,"PARTICLES.DISK requires 5 parameters: ID, coord X, coord Y, orientation, radius (radius is optional in this file).\n\n");
                    status = 0;
                    return;
                end
                
                % ID number
                id = values(1);
                if (~isnumeric(id) || floor(id) ~= ceil(id) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of PARTICLES.DISK.\n");
                    fprintf(2,"It must be a positive integer.\n\n");
                    status = 0;
                    return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~isnumeric(coord) || ~isa(coord,'double'))
                    fprintf(2,"Invalid data in model parts file: Coordinates of PARTICLES.DISK with ID %d.\n",id);
                    fprintf(2,"It must be a pair of numeric values.\n\n");
                    status = 0;
                    return;
                end
                
                % Orientation angle
                orient = values(4);
                if (~isnumeric(orient) || ~isa(orient,'double'))
                    fprintf(2,"Invalid data in model parts file: Orientation of PARTICLES.DISK with ID %d.\n",id);
                    fprintf(2,"It must be a numeric value.\n\n");
                    status = 0;
                    return;
                end
                
                % Radius
                if (length(values) == 5)
                    radius = values(5);
                    if (~isnumeric(radius) || ~isa(radius,'double') || radius <= 0)
                        fprintf(2,"Invalid data in model parts file: Radius of PARTICLES.DISK with ID %d.\n",id);
                        fprintf(2,"It must be a positive value.\n\n");
                        status = 0;
                        return;
                    end
                end
                
                % Create new particle object
                particle        = Particle_Disk();
                particle.id     = id;
                particle.coord  = coord;
                particle.orient = orient;
                if (length(values) == 5)
                    particle.radius = radius;
                end
                
                % Store handle to particle object
                drv.particles(id) = particle;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of PARTICLES.DISK is incompatible with provided data.\n\n");
                status = 0;
                return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsLine2D(~,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: WALLS.LINE2D is only allowed in 2D models.\n\n");
                status = 0;
                return;
            end
            
            % Total number of line2D walls
            n = fscanf(fid,'%d',1);
            if (isempty(n) || ~isnumeric(n) || floor(n) ~= ceil(n) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.LINE2D.\n");
                fprintf(2,"It must be a positive integer.\n\n");
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
                    fprintf(2,"WALLS.LINE2D requires 5 parameters: ID, coord X1, coord Y1, coord X2, coord Y2.\n\n");
                    status = 0;
                    return;
                end
                
                % ID number
                id = values(1);
                if (~isnumeric(id) || floor(id) ~= ceil(id) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of WALLS.LINE2D.\n");
                    fprintf(2,"It must be a positive integer.\n\n");
                    status = 0;
                    return;
                end
                
                % Coordinates
                coord = values(2:5);
                if (~isnumeric(coord) || ~isa(coord,'double'))
                    fprintf(2,"Invalid data in model parts file: Coordinates of WALLS.LINE2D with ID %d.\n",id);
                    fprintf(2,"It must be two pairs of numeric values: X1,Y1,X2,Y2.\n\n");
                    status = 0;
                    return;
                end
                
                % Create new wall object
                wall           = Wall_Line2D();
                wall.id        = id;
                wall.coord_ini = coord(1:2);
                wall.coord_end = coord(3:4);
                
                % Store handle to wall object
                drv.walls(id) = wall;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.LINE2D is incompatible with provided data.\n\n");
                status = 0;
                return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsCircle(~,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,"Invalid data: WALLS.CIRCLE is only allowed in 2D models.\n\n");
                status = 0;
                return;
            end
            
            % Total number of circle walls
            n = fscanf(fid,'%d',1);
            if (isempty(n) || ~isnumeric(n) || floor(n) ~= ceil(n) || n < 0)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.CIRCLE.\n");
                fprintf(2,"It must be a positive integer.\n\n");
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
                    fprintf(2,"WALLS.CIRCLE requires 4 parameters: ID, center coord X, center coord Y, radius.\n\n");
                    status = 0;
                    return;
                end
                
                % ID number
                id = values(1);
                if (~isnumeric(id) || floor(id) ~= ceil(id) || id <= 0)
                    fprintf(2,"Invalid data in model parts file: ID number of WALLS.CIRCLE.\n");
                    fprintf(2,"It must be a positive integer.\n\n");
                    status = 0;
                    return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~isnumeric(coord) || ~isa(coord,'double'))
                    fprintf(2,"Invalid data in model parts file: Center coordinates of WALLS.CIRCLE with ID %d.\n",id);
                    fprintf(2,"It must be a pair of numeric values: X,Y.\n\n");
                    status = 0;
                    return;
                end
                
                % Radius
                radius = values(4);
                if (~isnumeric(radius) || ~isa(radius,'double') || radius <= 0)
                    fprintf(2,"Invalid data in model parts file: Radius of WALLS.CIRCLE with ID %d.\n",id);
                    fprintf(2,"It must be a positive value.\n\n");
                    status = 0;
                    return;
                end
                
                % Create new wall object
                wall        = Wall_Circle();
                wall.id     = id;
                wall.center = coord;
                wall.radius = radius;
                
                % Store handle to wall object
                drv.walls(id) = wall;
            end
            
            if (i < n)
                fprintf(2,"Invalid data in model parts file: Total number of WALLS.CIRCLE is incompatible with provided data.\n\n");
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
                fprintf(2,"Invalid data in model parts file: NAME of MODELPART was not provided or is invalid.\n\n");
                status = 0;
                return;
            end
            line = regexp(line,' ','split');
            if (length(line) ~= 2 || ~strcmp(line{1},'NAME') || ismember(line{2},reserved))
                fprintf(2,"Invalid data in model parts file: NAME of MODELPART was not provided or is invalid.\n\n");
                status = 0;
                return;
            end
            mp.name = line{2};
            
            % Model part components
            line = deblank(fgetl(fid));
            if (isempty(line) || isnumeric(line))
                warning('off','backtrace');
                warning("Model part %s is empty.\n",mp.name);
                warning('on','backtrace');
                return;
            end
            line = regexp(line,' ','split');
            if (~ismember(line{1},reserved))
                fprintf(2,"Invalid data in model parts file: MODELPART can contain only two fields after its name, PARTICLES and WALLS.\n\n");
                status = 0;
                return;
            elseif (length(line) ~= 2 || isnan(str2double(line{2})) || floor(str2double(line{2})) ~= ceil(str2double(line{2})) || str2double(line{2}) < 0)
                fprintf(2,"Invalid data in model parts file: Number of %s of MODELPART %s was not provided correctly.\n\n",line{1},mp.name);
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
                    fprintf(2,"Invalid data in model parts file: Number of PARTICLES of MODELPART %s is not consistent with the provided IDs.\n\n",mp.name);
                    status = 0;
                    return;
                end
                
                % Store particles IDs
                mp.id_particles = particles;
                
                % Store handle to particle objects
                if (np > 0)
                    mp.particles = Particle();
                    for i = 1:np
                        id = particles(i);
                        if (floor(id) ~= ceil(id) || id <=0 || id > length(drv.particles))
                            fprintf(2,"Invalid data in model parts file: PARTICLES IDs of MODELPART %s is not consistent with existing particles.\n\n",mp.name);
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
                fprintf(2,"Invalid data in model parts file: MODELPART can contain only two fields after its name, PARTICLES and WALLS.\n\n");
                status = 0;
                return;
            elseif (length(line) ~= 2 || isnan(str2double(line{2})) || floor(str2double(line{2})) ~= ceil(str2double(line{2})) || str2double(line{2}) < 0)
                fprintf(2,"Invalid data in model parts file: Number of %s of MODELPART %s was not provided correctly.\n\n",line{1},mp.name);
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
                    fprintf(2,"Invalid data in model parts file: Number of WALLS of MODELPART %s is not consistent with the provided IDs.\n\n",mp.name);
                    status = 0;
                    return;
                end
                
                % Store walls IDs
                mp.id_walls = walls;
                
                % Store handle to walls objects
                if (nw > 0)
                    mp.walls = Wall();
                    for i = 1:nw
                        id = walls(i);
                        if (floor(id) ~= ceil(id) || id <=0 || id > length(drv.walls))
                            fprintf(2,"Invalid data in model parts file: WALLS IDs of MODELPART %s is not consistent with existing walls.\n\n",mp.name);
                            status = 0;
                            return;
                        end
                        mp.walls(i) = drv.walls(id);
                    end
                end
            end
            
            if (mp.n_particles == 0 && mp.n_walls == 0)
                warning('off','backtrace');
                warning("Model part %s is empty.\n",mp.name);
                warning('on','backtrace');
            end
        end
    end
end
