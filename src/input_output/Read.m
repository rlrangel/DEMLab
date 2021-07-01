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
    
    %% Public methods: Main functions
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
                status = this.getSearch(json,drv);
            end
            if (status)
                status = this.getBoundingBox(json,drv);
            end
            if (status)
                status = this.getSink(json,drv);
            end
            if (status)
                status = this.getGlobalCondition(json,drv);
            end
            if (status)
                status = this.getInitialCondition(json,drv);
            end
            if (status)
                status = this.getPrescribedCondition(json,drv,path);
            end
            if (status)
                status = this.getMaterial(json,drv);
            end
            if (status)
                status = this.getInteractionModel(json,drv);
            end
            if (status)
                status = this.getInteractionAssignment(json,drv);
            end
        end
        
        %------------------------------------------------------------------
        function status = check(this,drv)
            status = 1;
            if (status)
                status = this.checkDriver(drv);
            end
            if (status)
                status = this.checkParticles(drv);
            end
            if (status)
                status = this.checkWalls(drv);
            end
            
            % All elements have an interaction model defined between them;
            % Interaction models are consistent;
        end
    end
    
    %% Public methods: Project parameters file
    methods
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
            if (~this.isStringArray(anl,1) ||...
               (~strcmp(anl,'mechanical') && ~strcmp(anl,'thermal') && ~strcmp(anl,'thermo_mechanical')))
                fprintf(2,'Invalid data in project parameters file: ProblemData.analysis_type.\n');
                fprintf(2,'Available options: mechanical, thermal, thermo_mechanical.\n');
                status = 0; return;
            elseif (strcmp(anl,'mechanical'))
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
            if (~this.isDoubleArray(dim,1) || dim ~= 2)
                fprintf(2,'Invalid data in project parameters file: ProblemData.dimension.\n');
                fprintf(2,'Available options: 2.\n');
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
                fprintf(2,'Error opening model parts file: %s\n', file);
                fprintf(2,'It must have the same path of the project parameters file.\n');
                status = 0; return;
            end
            
            % Look for tags
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
            
            % Checks
            if (drv.n_particles == 0)
                fprintf(2,'The model has no particle.\n');
                status = 0; return;
            elseif (drv.particles(drv.n_particles).id > drv.n_particles)
                fprintf(2,'Invalid numbering of particles: IDs cannot skip numbers.\n');
                status = 0; return;
            end
            if (drv.n_walls > 0 && drv.walls(drv.n_walls).id > drv.n_walls)
                fprintf(2,'Invalid numbering of walls: IDs cannot skip numbers.\n');
                status = 0; return;
            end
            for i = 1:drv.n_mparts
                if (length(findobj(drv.mparts,'name',drv.mparts(i).name)) > 1)
                    fprintf(2,'Invalid data in model parts file: Repeated model part name.\n');
                    status = 0; return;
                end
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
            elseif (~isfield(json.Solver,'auto_time_step'))
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
            if ((drv.type == drv.THERMO_MECHANICAL || drv.type == drv.MECHANICAL) && isfield(json.Solver,'integr_scheme_trans'))
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
            if ((drv.type == drv.THERMO_MECHANICAL || drv.type == drv.MECHANICAL) && isfield(json.Solver,'integr_scheme_rotat'))
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
            if ((drv.type == drv.THERMO_MECHANICAL || drv.type == drv.THERMAL) && isfield(json.Solver,'integr_scheme_therm'))
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
        function status = getSearch(this,json,drv)
            status = 1;
            if (~isfield(json,'Search'))
                fprintf(2,'Missing data in project parameters file: Search.\n');
                status = 0; return;
            elseif (~isfield(json.Search,'scheme'))
                fprintf(2,'Missing data in project parameters file: Search.scheme.\n');
                status = 0; return;
            end
            
            % Scheme
            scheme = string(json.Search.scheme);
            if (~this.isStringArray(scheme,1) || ~strcmp(scheme,'simple_loop'))
                fprintf(2,'Invalid data in project parameters file: Search.scheme.\n');
                fprintf(2,'Available options: simple_loop.\n');
                status = 0; return;
            elseif (strcmp(scheme,'simple_loop'))
                drv.search = Search_SimpleLoop();
            end
            
            % Search frequency
            if (isfield(json.Search,'search_frequency'))
                if (~this.isDoubleArray(json.Search.search_frequency,1) || json.Search.search_frequency <= 0)
                    fprintf(2,'Invalid data in project parameters file: Search.search_frequency.\n');
                    fprintf(2,'It must be a positive integer.\n');
                    status = 0; return;
                end
                drv.search.freq = json.Search.search_frequency;
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
                fprintf(2,'Available options: rectangle, circle, polygon.\n');
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
                if (warn == 1)
                    this.warn('Minimum limits of bounding box were not provided. Infinite limits were assumed.');
                elseif (warn == 2)
                    this.warn('Maximum limits of bounding box were not provided. Infinite limits were assumed.');
                elseif (warn == 3)
                    this.warn('Maximum and minimum limits of bounding box were not provided. Bounding box will not be considered.');
                    return;
                end
                if (limit_min(1) >= limit_max(1) || limit_min(2) >= limit_max(2))
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.limit_min or BoundingBox.limit_max.\n');
                    fprintf(2,'Minimum coordinates must be smaller than the maximum ones.\n');
                    status = 0;
                    return;
                end
                
                % Create object and set properties
                bbox = BBox_Rectangle();
                bbox.limit_min = limit_min;
                bbox.limit_max = limit_max;
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
                bbox.center = center;
                bbox.radius = radius;
                drv.bbox = bbox;
                
            % POLYGON
            elseif (strcmp(shape,'polygon'))
                if (~isfield(BB,'points_x') || ~isfield(BB,'points_y'))
                    fprintf(2,'Invalid data in project parameters file: Missing BoundingBox.points_x and/or BoundingBox.points_y.\n');
                    status = 0; return;
                end
                x = BB.points_x;
                y = BB.points_y;
                
                % points_x / points_y
                if (~this.isDoubleArray(x,length(x)) || ~this.isDoubleArray(y,length(y)))
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.points_x and/or BoundingBox.points_y.\n');
                    fprintf(2,'It must be a list of numeric values with the X or Y coordinates of polygon points.\n');
                    status = 0; return;
                elseif (length(x) ~= length(y))
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.\n');
                    fprintf(2,'Lists of X and Y coordinates must have the same size.\n');
                    status = 0; return;
                end
                
                % Check for valid polygon
                warning off MATLAB:polyshape:repairedBySimplify;
                warning off MATLAB:polyshape:boolOperationFailed
                p = polyshape(x,y);
                if (p.NumRegions ~= 1)
                    fprintf(2,'Invalid data in project parameters file: BoundingBox.\n');
                    fprintf(2,'Inconsistent polygon shape.\n');
                    status = 0; return;
                end
                
                % Create object and set properties
                bbox = BBox_Polygon();
                bbox.coord_x = x;
                bbox.coord_y = y;
                drv.bbox = bbox;
            else
                fprintf(2,'Invalid data in project parameters file: BoundingBox.shape.\n');
                fprintf(2,'Available options: rectangle, circle, polygon.\n');
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
                drv.bbox.interval = interval;
            end
        end
        
        %------------------------------------------------------------------
        function status = getSink(this,json,drv)
            status = 1;
            if (~isfield(json,'Sink'))
                return;
            end
            
            for i = 1:length(json.Sink)
                S = json.Sink(i);
                
                % Shape
                if (~isfield(S,'shape'))
                    fprintf(2,'Missing data in project parameters file: Sink.shape.\n');
                    fprintf(2,'Available options: rectangle, circle, polygon.\n');
                    status = 0; return;
                end
                shape = string(S.shape);
                if (~this.isStringArray(shape,1))
                    fprintf(2,'Invalid data in project parameters file: Sink.shape.\n');
                    status = 0; return;
                end
                
                % RECTANGLE
                if (strcmp(shape,'rectangle'))
                    if (~isfield(S,'limit_min') || ~isfield(S,'limit_max'))
                        fprintf(2,'Invalid data in project parameters file: Missing Sink.limit_min and/or Sink.limit_max.\n');
                        status = 0; return;
                    end
                    limit_min = S.limit_min;
                    limit_max = S.limit_max;
                    
                    % Minimum limits
                    if (~this.isDoubleArray(limit_min,2))
                        fprintf(2,'Invalid data in project parameters file: Sink.limit_min.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y coordinates of bottom-left corner.\n');
                        status = 0; return;
                    end
                    
                    % Maximum limits
                    if (~this.isDoubleArray(limit_max,2))
                        fprintf(2,'Invalid data in project parameters file: Sink.limit_max.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y coordinates of top-right corner.\n');
                        status = 0; return;
                    end
                    
                    % Check consistency
                    if (limit_min(1) >= limit_max(1) || limit_min(2) >= limit_max(2))
                        fprintf(2,'Invalid data in project parameters file: Sink.limit_min or Sink.limit_max.\n');
                        fprintf(2,'Minimum coordinates must be smaller than the maximum ones.\n');
                        status = 0;
                        return;
                    end
                    
                    % Create object and set properties
                    sink = Sink_Rectangle();
                    sink.limit_min = limit_min;
                    sink.limit_max = limit_max;
                    drv.sink(i) = sink;
                    
                % CIRCLE
                elseif (strcmp(shape,'circle'))
                    if (~isfield(S,'center') || ~isfield(S,'radius'))
                        fprintf(2,'Invalid data in project parameters file: Missing Sink.center and/or Sink.radius.\n');
                        status = 0; return;
                    end
                    center = S.center;
                    radius = S.radius;
                    
                    % Center
                    if (~this.isDoubleArray(center,2))
                        fprintf(2,'Invalid data in project parameters file: Sink.center.\n');
                        fprintf(2,'It must be a pair of numeric values with X,Y coordinates of center point.\n');
                        status = 0; return;
                    end
                    
                    % Radius
                    if (~this.isDoubleArray(radius,1) || radius <= 0)
                        fprintf(2,'Invalid data in project parameters file: Sink.radius.\n');
                        fprintf(2,'It must be a positive value.\n');
                        status = 0; return;
                    end
                    
                    % Create object and set properties
                    sink = Sink_Circle();
                    sink.center = center;
                    sink.radius = radius;
                    drv.sink(i) = sink;
                    
                % POLYGON
                elseif (strcmp(shape,'polygon'))
                    if (~isfield(S,'points_x') || ~isfield(S,'points_y'))
                        fprintf(2,'Invalid data in project parameters file: Missing Sink.points_x and/or Sink.points_y.\n');
                        status = 0; return;
                    end
                    x = S.points_x;
                    y = S.points_y;
                    
                    % points_x / points_y
                    if (~this.isDoubleArray(x,length(x)) || ~this.isDoubleArray(y,length(y)))
                        fprintf(2,'Invalid data in project parameters file: Sink.points_x and/or Sink.points_y.\n');
                        fprintf(2,'It must be a list of numeric values with the X or Y coordinates of polygon points.\n');
                        status = 0; return;
                    elseif (length(x) ~= length(y))
                        fprintf(2,'Invalid data in project parameters file: Sink.\n');
                        fprintf(2,'Lists of X and Y coordinates must have the same size.\n');
                        status = 0; return;
                    end
                    
                    % Check for valid polygon
                    warning off MATLAB:polyshape:repairedBySimplify;
                    warning off MATLAB:polyshape:boolOperationFailed
                    p = polyshape(x,y);
                    if (p.NumRegions ~= 1)
                        fprintf(2,'Invalid data in project parameters file: Sink.\n');
                        fprintf(2,'Inconsistent polygon shape.\n');
                        status = 0; return;
                    end
                    
                    % Create object and set properties
                    sink = Sink_Polygon();
                    sink.coord_x = x;
                    sink.coord_y = y;
                    drv.sink = sink;
                    
                else
                    fprintf(2,'Invalid data in project parameters file: Sink.shape.\n');
                    fprintf(2,'Available options: rectangle, circle, polygon.\n');
                    status = 0; return;
                end
                
                % Interval
                if (isfield(S,'interval'))
                    interval = S.interval;
                    if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                        fprintf(2,'Invalid data in project parameters file: Sink.interval.\n');
                        fprintf(2,'It must be a pair of numeric values and the minimum value must be smaller than the maximum.\n');
                        status = 0; return;
                    end
                    drv.sink(i).interval = interval;
                end
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
                drv.gravity = g;
            end
        end
        
        %------------------------------------------------------------------
        function status = getInitialCondition(this,json,drv)
            status = 1;
            if (~isfield(json,'InitialCondition'))
                return;
            end
            IC = json.InitialCondition;
            
            fields = fieldnames(IC);
            for i = 1:length(fields)
                f = string(fields(i));
                if (~strcmp(f,'TranslationalVelocity') &&...
                    ~strcmp(f,'RotationalVelocity')    &&...
                    ~strcmp(f,'temperature'))
                    this.warn('A nonexistent field was identified in InitialCondition. It will be ignored.');
                end
            end
            
            % TRANSLATIONAL VELOCITY
            if (isfield(IC,'TranslationalVelocity'))
                for i = 1:length(IC.TranslationalVelocity)
                    TV = IC.TranslationalVelocity(i);
                    if (~isfield(TV,'value') || ~isfield(TV,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: InitialCondition.TranslationalVelocity must have value and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Velocity value
                    val = TV.value;
                    if (~this.isDoubleArray(val,2))
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
                            [drv.particles.veloc_trl] = deal(val);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warn('Nonexistent model part used in InitialCondition.TranslationalVelocity.');
                                continue;
                            end
                            [mp.particles.veloc_trl] = deal(val);
                        end
                    end
                end
            end
            
            % ROTATIONAL VELOCITY
            if (isfield(IC,'RotationalVelocity'))                
                for i = 1:length(IC.RotationalVelocity)
                    RV = IC.RotationalVelocity(i);
                    if (~isfield(RV,'value') || ~isfield(RV,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: InitialCondition.RotationalVelocity must have value and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Velocity value
                    val = RV.value;
                    if (~this.isDoubleArray(val,1))
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
                            [drv.particles.veloc_rot] = deal(val);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warn('Nonexistent model part used in InitialCondition.RotationalVelocity.');
                                continue;
                            end
                            [mp.particles.veloc_rot] = deal(val);
                        end
                    end
                end
            end
            
            % TEMPERATURE
            if (isfield(IC,'temperature'))
                for i = 1:length(IC.temperature)
                    T = IC.temperature(i);
                    if (~isfield(T,'value') || ~isfield(T,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: InitialCondition.temperature must have value and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Temperature value
                    val = T.value;
                    if (~this.isDoubleArray(val,1))
                        fprintf(2,'Invalid data in project parameters file: InitialCondition.temperature.value.\n');
                        fprintf(2,'It must be a numeric value with temperature.\n');
                        status = 0; return;
                    end
                    
                    % Apply initial temperature to selected particles
                    model_parts = string(T.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            fprintf(2,'Invalid data in project parameters file: InitialCondition.temperature.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.temperature] = deal(val);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warn('Nonexistent model part used in InitialCondition.temperature.');
                                continue;
                            end
                            [mp.particles.temperature] = deal(val);
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getPrescribedCondition(this,json,drv,path)
            status = 1;
            if (~isfield(json,'PrescribedCondition'))
                return;
            end
            PC = json.PrescribedCondition;
            
            fields = fieldnames(PC);
            for i = 1:length(fields)
                f = string(fields(i));
                if (~strcmp(f,'force')     &&...
                    ~strcmp(f,'torque')    &&...
                    ~strcmp(f,'heat_flux') &&...
                    ~strcmp(f,'heat_rate'))
                    this.warn('A nonexistent field was identified in PrescribedCondition. It will be ignored.');
                end
            end
            % In the following, the types of conditions have very similar codes
            
            % FORCE
            if (isfield(PC,'force'))
                for i = 1:length(PC.force)
                    F = PC.force(i);
                    if (~isfield(F,'type') || ~isfield(F,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: PrescribedCondition.force must have type and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(F.type);
                    if (~this.isStringArray(type,1))
                        fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.type.\n');
                        status = 0; return;
                        
                    elseif (strcmp(type,'uniform'))
                        % Create object
                        pc = PC_Uniform();
                        
                        % Value
                        if (~isfield(F,'value'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.force.value.\n');
                            status = 0; return;
                        end
                        val = F.value;
                        if (~this.isDoubleArray(val,2))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.value.\n');
                            fprintf(2,'It must be a pair of numeric values with X,Y force components.\n');
                            status = 0; return;
                        end
                        pc.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        pc = PC_Linear();
                        
                        % Initial value
                        if (isfield(F,'initial_value'))
                            val = F.initial_value;
                            if (~this.isDoubleArray(val,2))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.initial_value.\n');
                                fprintf(2,'It must be a pair of numeric values with X,Y force components.\n');
                                status = 0; return;
                            end
                            pc.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(F,'slope'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.force.slope.\n');
                            status = 0; return;
                        end
                        slope = F.slope;
                        if (~this.isDoubleArray(slope,2))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.slope.\n');
                            fprintf(2,'It must be a pair of numeric values with X,Y components of change rate.\n');
                            status = 0; return;
                        end
                        pc.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        pc = PC_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(F,'base_value') || ~isfield(F,'amplitude') || ~isfield(F,'period'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.force.\n');
                            fprintf(2,'Oscillatory condition requires at least 3 fields: base_value, amplitude, period.\n');
                            status = 0; return;
                        end
                        val       = F.base_value;
                        amplitude = F.amplitude;
                        period    = F.period;
                        if (~this.isDoubleArray(val,2))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.base_value.\n');
                            fprintf(2,'It must be a pair of numeric values with X,Y force components.\n');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,2) || any(amplitude < 0))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.amplitude.\n');
                            fprintf(2,'It must be a pair of numeric values with X,Y force components.\n');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.period.\n');
                            fprintf(2,'It must be a positive value with the period of oscillation.\n');
                            status = 0; return;
                        end
                        pc.base_value = val;
                        pc.amplitude  = amplitude;
                        pc.period     = period;
                        
                        % Shift
                        if (isfield(F,'shift'))
                            shift = F.shift;
                            if (~this.isDoubleArray(shift,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.shift.\n');
                                fprintf(2,'It must be a numeric value with the shift of the oscillation.\n');
                                status = 0; return;
                            end
                            pc.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        pc = PC_Table();
                        
                        % Table values
                        if (isfield(F,'values'))
                            vals = F.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.values.\n');
                                fprintf(2,'It must be a numeric table with the first row as the independent variable values and the others as the dependent variable values.\n');
                                status = 0; return;
                            end
                        elseif (isfield(F,'file'))
                            file = F.file;
                            if (~this.isStringArray(file,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.file.\n');
                                fprintf(2,'It must be a string with the values file name.\n');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(path,file),3);
                            if (status == 0)
                                return;
                            end
                        else
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.force.values or PrescribedCondition.force.file.\n');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 3)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.values.\n');
                            fprintf(2,'It must contain 3 columns (one for the independent variable values and two for the X,Y force components), and at least 2 points.\n');
                            status = 0; return;
                        end
                        pc.val_x = vals(:,1);
                        pc.val_y = vals(:,2:3);
                        
                        % Interpolation method
                        if (isfield(F,'interpolation'))
                            interp = F.interpolation;
                            if (~this.isStringArray(interp,1) ||...
                               (~strcmp(interp,'linear') &&...
                                ~strcmp(interp,'makima') &&...
                                ~strcmp(interp,'cubic')  &&...
                                ~strcmp(interp,'pchip')  &&...
                                ~strcmp(interp,'spline')))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.interpolation.\n');
                                fprintf(2,'It must be a string with the interpolation method: linear, makima, cubic, pchip or spline.\n');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(pc.val_x,1) < 2)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.values.\n');
                                    fprintf(2,'It must contain at least 2 points for linear interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(pc.val_x,1) < 2)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.values.\n');
                                    fprintf(2,'It must contain at least 2 points for makima interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(pc.val_x,1) < 3)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.values.\n');
                                    fprintf(2,'It must contain at least 3 points for cubic interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(pc.val_x,1) < 4)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.values.\n');
                                    fprintf(2,'It must contain at least 4 points for pchip interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(pc.val_x,1) < 4)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.values.\n');
                                    fprintf(2,'It must contain at least 4 points for spline interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_SPLINE;
                            end
                        end
                    else
                        fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.type.\n');
                        fprintf(2,'Available options: uniform, linear, oscillatory, table.\n');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(F,'interval'))
                        interval = F.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.interval.\n');
                            fprintf(2,'It must be a pair of numeric values and the minimum value must be smaller than the maximum.\n');
                            status = 0; return;
                        end
                        pc.interval = interval;
                    end
                    
                    % Add handle to prescribed condition to selected particles
                    model_parts = string(F.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.force.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.pc_forces] = deal(pc);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warn('Nonexistent model part used in PrescribedCondition.force.');
                                continue;
                            end
                            [mp.particles.pc_forces] = deal(pc);
                        end
                    end
                    
                    % Add to global list in driver
                    drv.prescond(end+1) = pc;
                    drv.n_prescond = drv.n_prescond + 1;
                end
            end
            
            
            % TORQUE
            if (isfield(PC,'torque'))
                for i = 1:length(PC.torque)
                    T = PC.torque(i);
                    if (~isfield(T,'type') || ~isfield(T,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: PrescribedCondition.torque must have type and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(T.type);
                    if (~this.isStringArray(type,1))
                        fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.type.\n');
                        status = 0; return;
                        
                    elseif (strcmp(type,'uniform'))
                        % Create object
                        pc = PC_Uniform();
                        
                        % Value
                        if (~isfield(T,'value'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.torque.value.\n');
                            status = 0; return;
                        end
                        val = T.value;
                        if (~this.isDoubleArray(val,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.value.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        end
                        pc.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        pc = PC_Linear();
                        
                        % Initial value
                        if (isfield(T,'initial_value'))
                            val = T.initial_value;
                            if (~this.isDoubleArray(val,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.initial_value.\n');
                                fprintf(2,'It must be a numeric value.\n');
                                status = 0; return;
                            end
                            pc.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(T,'slope'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.torque.slope.\n');
                            status = 0; return;
                        end
                        slope = T.slope;
                        if (~this.isDoubleArray(slope,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.slope.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        end
                        pc.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        pc = PC_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(T,'base_value') || ~isfield(T,'amplitude') || ~isfield(T,'period'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.torque.\n');
                            fprintf(2,'Oscillatory condition requires at least 3 fields: base_value, amplitude, period.\n');
                            status = 0; return;
                        end
                        val       = T.base_value;
                        amplitude = T.amplitude;
                        period    = T.period;
                        if (~this.isDoubleArray(val,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.base_value.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,1) || amplitude < 0)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.amplitude.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.period.\n');
                            fprintf(2,'It must be a positive value with the period of oscillation.\n');
                            status = 0; return;
                        end
                        pc.base_value = val;
                        pc.amplitude  = amplitude;
                        pc.period     = period;
                        
                        % Shift
                        if (isfield(T,'shift'))
                            shift = T.shift;
                            if (~this.isDoubleArray(shift,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.shift.\n');
                                fprintf(2,'It must be a numeric value with the shift of the oscillation.\n');
                                status = 0; return;
                            end
                            pc.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        pc = PC_Table();
                        
                        % Table values
                        if (isfield(T,'values'))
                            vals = T.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.values.\n');
                                fprintf(2,'It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values.\n');
                                status = 0; return;
                            end
                        elseif (isfield(T,'file'))
                            file = T.file;
                            if (~this.isStringArray(file,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.file.\n');
                                fprintf(2,'It must be a string with the values file name.\n');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(path,file),2);
                            if (status == 0)
                                return;
                            end
                        else
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.torque.values or PrescribedCondition.torque.file.\n');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 2)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.values.\n');
                            fprintf(2,'It must contain 2 columns (one for the independent variable values and another for the torque values), and at least 2 points.\n');
                            status = 0; return;
                        end
                        pc.val_x = vals(:,1);
                        pc.val_y = vals(:,2);
                        
                        % Interpolation method
                        if (isfield(T,'interpolation'))
                            interp = T.interpolation;
                            if (~this.isStringArray(interp,1) ||...
                               (~strcmp(interp,'linear') &&...
                                ~strcmp(interp,'makima') &&...
                                ~strcmp(interp,'cubic')  &&...
                                ~strcmp(interp,'pchip')  &&...
                                ~strcmp(interp,'spline')))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.interpolation.\n');
                                fprintf(2,'It must be a string with the interpolation method: linear, makima, cubic, pchip or spline.\n');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(pc.val_x,1) < 2)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.values.\n');
                                    fprintf(2,'It must contain at least 2 points for linear interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(pc.val_x,1) < 2)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.values.\n');
                                    fprintf(2,'It must contain at least 2 points for makima interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(pc.val_x,1) < 3)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.values.\n');
                                    fprintf(2,'It must contain at least 3 points for cubic interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(pc.val_x,1) < 4)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.values.\n');
                                    fprintf(2,'It must contain at least 4 points for pchip interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(pc.val_x,1) < 4)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.values.\n');
                                    fprintf(2,'It must contain at least 4 points for spline interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_SPLINE;
                            end
                        end
                    else
                        fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.type.\n');
                        fprintf(2,'Available options: uniform, linear, oscillatory, table.\n');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(T,'interval'))
                        interval = T.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.interval.\n');
                            fprintf(2,'It must be a pair of numeric values and the minimum value must be smaller than the maximum.\n');
                            status = 0; return;
                        end
                        pc.interval = interval;
                    end
                    
                    % Add handle to prescribed condition to selected particles
                    model_parts = string(T.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.torque.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.pc_torques] = deal(pc);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warn('Nonexistent model part used in PrescribedCondition.torque.');
                                continue;
                            end
                            [mp.particles.pc_torques] = deal(pc);
                        end
                    end
                    
                    % Add to global list in driver
                    drv.prescond(end+1) = pc;
                    drv.n_prescond = drv.n_prescond + 1;
                end
            end
            
            % HEAT FLUX
            if (isfield(PC,'heat_flux'))
                for i = 1:length(PC.heat_flux)
                    HF = PC.heat_flux(i);
                    if (~isfield(HF,'type') || ~isfield(HF,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_flux must have type and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(HF.type);
                    if (~this.isStringArray(type,1))
                        fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.type.\n');
                        status = 0; return;
                        
                    elseif (strcmp(type,'uniform'))
                        % Create object
                        pc = PC_Uniform();
                        
                        % Value
                        if (~isfield(HF,'value'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_flux.value.\n');
                            status = 0; return;
                        end
                        val = HF.value;
                        if (~this.isDoubleArray(val,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.value.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        end
                        pc.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        pc = PC_Linear();
                        
                        % Initial value
                        if (isfield(HF,'initial_value'))
                            val = HF.initial_value;
                            if (~this.isDoubleArray(val,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.initial_value.\n');
                                fprintf(2,'It must be a numeric value.\n');
                                status = 0; return;
                            end
                            pc.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(HF,'slope'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_flux.slope.\n');
                            status = 0; return;
                        end
                        slope = HF.slope;
                        if (~this.isDoubleArray(slope,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.slope.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        end
                        pc.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        pc = PC_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(HF,'base_value') || ~isfield(HF,'amplitude') || ~isfield(HF,'period'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_flux.\n');
                            fprintf(2,'Oscillatory condition requires at least 3 fields: base_value, amplitude, period.\n');
                            status = 0; return;
                        end
                        val       = HF.base_value;
                        amplitude = HF.amplitude;
                        period    = HF.period;
                        if (~this.isDoubleArray(val,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.base_value.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,1) || amplitude < 0)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.amplitude.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.period.\n');
                            fprintf(2,'It must be a positive value with the period of oscillation.\n');
                            status = 0; return;
                        end
                        pc.base_value = val;
                        pc.amplitude  = amplitude;
                        pc.period     = period;
                        
                        % Shift
                        if (isfield(HF,'shift'))
                            shift = HF.shift;
                            if (~this.isDoubleArray(shift,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.shift.\n');
                                fprintf(2,'It must be a numeric value with the shift of the oscillation.\n');
                                status = 0; return;
                            end
                            pc.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        pc = PC_Table();
                        
                        % Table values
                        if (isfield(HF,'values'))
                            vals = HF.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.values.\n');
                                fprintf(2,'It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values.\n');
                                status = 0; return;
                            end
                        elseif (isfield(HF,'file'))
                            file = HF.file;
                            if (~this.isStringArray(file,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.file.\n');
                                fprintf(2,'It must be a string with the values file name.\n');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(path,file),2);
                            if (status == 0)
                                return;
                            end
                        else
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_flux.values or PrescribedCondition.heat_flux.file.\n');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 2)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.values.\n');
                            fprintf(2,'It must contain 2 columns (one for the independent variable values and another for the heat flux values), and at least 2 points.\n');
                            status = 0; return;
                        end
                        pc.val_x = vals(:,1);
                        pc.val_y = vals(:,2);
                        
                        % Interpolation method
                        if (isfield(HF,'interpolation'))
                            interp = HF.interpolation;
                            if (~this.isStringArray(interp,1) ||...
                               (~strcmp(interp,'linear') &&...
                                ~strcmp(interp,'makima') &&...
                                ~strcmp(interp,'cubic')  &&...
                                ~strcmp(interp,'pchip')  &&...
                                ~strcmp(interp,'spline')))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.interpolation.\n');
                                fprintf(2,'It must be a string with the interpolation method: linear, makima, cubic, pchip or spline.\n');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(pc.val_x,1) < 2)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.values.\n');
                                    fprintf(2,'It must contain at least 2 points for linear interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(pc.val_x,1) < 2)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.values.\n');
                                    fprintf(2,'It must contain at least 2 points for makima interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(pc.val_x,1) < 3)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.values.\n');
                                    fprintf(2,'It must contain at least 3 points for cubic interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(pc.val_x,1) < 4)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.values.\n');
                                    fprintf(2,'It must contain at least 4 points for pchip interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(pc.val_x,1) < 4)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.values.\n');
                                    fprintf(2,'It must contain at least 4 points for spline interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_SPLINE;
                            end
                        end
                    else
                        fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.type.\n');
                        fprintf(2,'Available options: uniform, linear, oscillatory, table.\n');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(HF,'interval'))
                        interval = HF.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.interval.\n');
                            fprintf(2,'It must be a pair of numeric values and the minimum value must be smaller than the maximum.\n');
                            status = 0; return;
                        end
                        pc.interval = interval;
                    end
                    
                    % Add handle to prescribed condition to selected particles
                    model_parts = string(HF.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_flux.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.pc_heatfluxes] = deal(pc);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warn('Nonexistent model part used in PrescribedCondition.heat_flux.');
                                continue;
                            end
                            [mp.particles.pc_heatfluxes] = deal(pc);
                        end
                    end
                    
                    % Add to global list in driver
                    drv.prescond(end+1) = pc;
                    drv.n_prescond = drv.n_prescond + 1;
                end
            end
            
            % HEAT RATE
            if (isfield(PC,'heat_rate'))
                for i = 1:length(PC.heat_rate)
                    HF = PC.heat_rate(i);
                    if (~isfield(HF,'type') || ~isfield(HF,'model_parts'))
                        fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_rate must have type and model_parts.\n');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(HF.type);
                    if (~this.isStringArray(type,1))
                        fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.type.\n');
                        status = 0; return;
                        
                    elseif (strcmp(type,'uniform'))
                        % Create object
                        pc = PC_Uniform();
                        
                        % Value
                        if (~isfield(HF,'value'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_rate.value.\n');
                            status = 0; return;
                        end
                        val = HF.value;
                        if (~this.isDoubleArray(val,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.value.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        end
                        pc.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        pc = PC_Linear();
                        
                        % Initial value
                        if (isfield(HF,'initial_value'))
                            val = HF.initial_value;
                            if (~this.isDoubleArray(val,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.initial_value.\n');
                                fprintf(2,'It must be a numeric value.\n');
                                status = 0; return;
                            end
                            pc.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(HF,'slope'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_rate.slope.\n');
                            status = 0; return;
                        end
                        slope = HF.slope;
                        if (~this.isDoubleArray(slope,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.slope.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        end
                        pc.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        pc = PC_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(HF,'base_value') || ~isfield(HF,'amplitude') || ~isfield(HF,'period'))
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_rate.\n');
                            fprintf(2,'Oscillatory condition requires at least 3 fields: base_value, amplitude, period.\n');
                            status = 0; return;
                        end
                        val       = HF.base_value;
                        amplitude = HF.amplitude;
                        period    = HF.period;
                        if (~this.isDoubleArray(val,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.base_value.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,1) || amplitude < 0)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.amplitude.\n');
                            fprintf(2,'It must be a numeric value.\n');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.period.\n');
                            fprintf(2,'It must be a positive value with the period of oscillation.\n');
                            status = 0; return;
                        end
                        pc.base_value = val;
                        pc.amplitude  = amplitude;
                        pc.period     = period;
                        
                        % Shift
                        if (isfield(HF,'shift'))
                            shift = HF.shift;
                            if (~this.isDoubleArray(shift,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.shift.\n');
                                fprintf(2,'It must be a numeric value with the shift of the oscillation.\n');
                                status = 0; return;
                            end
                            pc.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        pc = PC_Table();
                        
                        % Table values
                        if (isfield(HF,'values'))
                            vals = HF.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.values.\n');
                                fprintf(2,'It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values.\n');
                                status = 0; return;
                            end
                        elseif (isfield(HF,'file'))
                            file = HF.file;
                            if (~this.isStringArray(file,1))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.file.\n');
                                fprintf(2,'It must be a string with the values file name.\n');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(path,file),2);
                            if (status == 0)
                                return;
                            end
                        else
                            fprintf(2,'Missing data in project parameters file: PrescribedCondition.heat_rate.values or PrescribedCondition.heat_rate.file.\n');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 2)
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.values.\n');
                            fprintf(2,'It must contain 2 columns (one for the independent variable values and another for the heat rate values), and at least 2 points.\n');
                            status = 0; return;
                        end
                        pc.val_x = vals(:,1);
                        pc.val_y = vals(:,2);
                        
                        % Interpolation method
                        if (isfield(HF,'interpolation'))
                            interp = HF.interpolation;
                            if (~this.isStringArray(interp,1) ||...
                               (~strcmp(interp,'linear') &&...
                                ~strcmp(interp,'makima') &&...
                                ~strcmp(interp,'cubic')  &&...
                                ~strcmp(interp,'pchip')  &&...
                                ~strcmp(interp,'spline')))
                                fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.interpolation.\n');
                                fprintf(2,'It must be a string with the interpolation method: linear, makima, cubic, pchip or spline.\n');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(pc.val_x,1) < 2)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.values.\n');
                                    fprintf(2,'It must contain at least 2 points for linear interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(pc.val_x,1) < 2)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.values.\n');
                                    fprintf(2,'It must contain at least 2 points for makima interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(pc.val_x,1) < 3)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.values.\n');
                                    fprintf(2,'It must contain at least 3 points for cubic interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(pc.val_x,1) < 4)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.values.\n');
                                    fprintf(2,'It must contain at least 4 points for pchip interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(pc.val_x,1) < 4)
                                    fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.values.\n');
                                    fprintf(2,'It must contain at least 4 points for spline interpolation.\n');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_SPLINE;
                            end
                        end
                    else
                        fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.type.\n');
                        fprintf(2,'Available options: uniform, linear, oscillatory, table.\n');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(HF,'interval'))
                        interval = HF.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.interval.\n');
                            fprintf(2,'It must be a pair of numeric values and the minimum value must be smaller than the maximum.\n');
                            status = 0; return;
                        end
                        pc.interval = interval;
                    end
                    
                    % Add handle to prescribed condition to selected particles
                    model_parts = string(HF.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            fprintf(2,'Invalid data in project parameters file: PrescribedCondition.heat_rate.model_parts.\n');
                            fprintf(2,'It must be a list of strings containing the names of the model parts.\n');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.pc_heatrates] = deal(pc);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warn('Nonexistent model part used in PrescribedCondition.heat_rate.');
                                continue;
                            end
                            [mp.particles.pc_heatrates] = deal(pc);
                        end
                    end
                    
                    % Add to global list in driver
                    drv.prescond(end+1) = pc;
                    drv.n_prescond = drv.n_prescond + 1;
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
                    elseif (prop.thermal_expansion < 0)
                        msg = msg + 1;
                    end
                    mat.expansion = prop.thermal_expansion;
                end
                
                if (msg < 0)
                    fprintf(2,'Invalid data in project parameters file: Material.properties.\n');
                    fprintf(2,'Properties must be numerical values.\n');
                    status = 0; return;
                elseif(msg > 0)
                    this.warn('Unphysical value was found for material property.');
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
                        [drv.particles.material] = deal(mat);
                    elseif (strcmp(mp_name,'WALLS'))
                        [drv.walls.material] = deal(mat);
                    else
                        mp = findobj(drv.mparts,'name',name);
                        if (isempty(mp))
                            this.warn('Nonexistent model part used in Material.');
                            continue;
                        end
                        [mp.material.material] = deal(mat);
                        [mp.material.walls]    = deal(mat);
                    end
                end
            end
            
            % Checks
            if (drv.n_materials == 0)
                fprintf(2,'Invalid data in project parameters file: No valid material was found.\n');
                status = 0; return;
            else
                for i = 1:drv.n_materials
                    if (length(findobj(drv.materials,'name',drv.materials(i).name)) > 1)
                        fprintf(2,'Invalid data in project parameters file: Repeated material name.\n');
                        status = 0; return;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getInteractionModel(this,json,drv)
            status = 1;
            if (~isfield(json,'InteractionModel') || isempty(json.InteractionModel))
                fprintf(2,'Missing data in project parameters file: InteractionModel.\n');
                status = 0; return;
            end
            
            % Single case: Only 1 interaction model provided
            % (applied to the interaction between all elements)
            if (length(json.InteractionModel) == 1)
                % Create base object for common interactions
                % IT IS CONSIDERING ONLY DISK-DISK INTERACTIONS
                drv.search.b_interact = Interact();
                
                % Contact kinematics model
                drv.search.b_interact.contact_kinematics = ContactKinematics();
                
                % Contact normal force model
                if (~this.interactContactForceNormal(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
                
                % Contact tangent force model
                if (~this.interactContactForceTangent(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
                
                % Contact thermal conduction model
                if (~this.interactContactConduction(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
            end
            
            % Multiple case:
            if (length(json.InteractionModel) > 1)
               % TODO 
            end
        end
        
        %------------------------------------------------------------------
        function status = getInteractionAssignment(this,json,drv)
            status = 1;
            if (~isempty(drv.search.b_interact))
                if (isfield(json,'InteractionAssignment'))
                    this.warn('Only one InteractionModel was created and will be applied to all interactions, so InteractionAssignment will be ignored.');
                end
                return;
            elseif (~isfield(json,'InteractionAssignment'))
                fprintf(2,'Missing data in project parameters file: InteractionModel.\n');
                status = 0; return;
            end
        end
    end
    
    %% Public methods: Model parts file
    methods
        %------------------------------------------------------------------
        function status = readParticlesDisk(this,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,'Invalid data: PARTICLES.DISK is only allowed in 2D models.\n');
                status = 0; return;
            end
            
            % Total number of disk particles
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                fprintf(2,'Invalid data in model parts file: Total number of PARTICLES.DISK.\n');
                fprintf(2,'It must be a positive integer.\n');
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
                    fprintf(2,'Invalid data in model parts file: Number of parameters of PARTICLES.DISK.\n');
                    fprintf(2,'It requires 5 parameters: ID, coord X, coord Y, orientation, radius (radius is optional in this file).\n');
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    fprintf(2,'Invalid data in model parts file: ID number of PARTICLES.DISK.\n');
                    fprintf(2,'It must be a positive integer.\n');
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~this.isDoubleArray(coord,2))
                    fprintf(2,'Invalid data in model parts file: Coordinates of PARTICLES.DISK with ID %d.\n',id);
                    fprintf(2,'It must be a pair of numeric values.\n');
                    status = 0; return;
                end
                
                % Orientation angle
                orient = values(4);
                if (~this.isDoubleArray(orient,1))
                    fprintf(2,'Invalid data in model parts file: Orientation of PARTICLES.DISK with ID %d.\n',id);
                    fprintf(2,'It must be a numeric value.\n');
                    status = 0; return;
                end
                
                % Radius
                if (length(values) == 5)
                    radius = values(5);
                    if (~this.isDoubleArray(radius,1) || radius <= 0)
                        fprintf(2,'Invalid data in model parts file: Radius of PARTICLES.DISK with ID %d.\n',id);
                        fprintf(2,'It must be a positive value.\n');
                        status = 0; return;
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
                if (id <= length(drv.particles) && ~isempty(drv.particles(id).id))
                    fprintf(2,'Invalid numbering of particles: IDs cannot be repeated.\n');
                    status = 0; return;
                end
                drv.particles(id) = particle;
            end
            
            if (i < n)
                fprintf(2,'Invalid data in model parts file: Total number of PARTICLES.DISK is incompatible with provided data.\n');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsLine2D(this,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,'Invalid data: WALLS.LINE2D is only allowed in 2D models.\n');
                status = 0; return;
            end
            
            % Total number of line2D walls
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                fprintf(2,'Invalid data in model parts file: Total number of WALLS.LINE2D.\n');
                fprintf(2,'It must be a positive integer.\n');
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
                    fprintf(2,'Invalid data in model parts file: Number of parameters of WALLS.LINE2D.\n');
                    fprintf(2,'It requires 5 parameters: ID, coord X1, coord Y1, coord X2, coord Y2.\n');
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    fprintf(2,'Invalid data in model parts file: ID number of WALLS.LINE2D.\n');
                    fprintf(2,'It must be a positive integer.\n');
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:5);
                if (~this.isDoubleArray(coord,4))
                    fprintf(2,'Invalid data in model parts file: Coordinates of WALLS.LINE2D with ID %d.\n',id);
                    fprintf(2,'It must be two pairs of numeric values: X1,Y1,X2,Y2.\n');
                    status = 0; return;
                end
                
                % Create new wall object
                wall           = Wall_Line2D();
                wall.id        = id;
                wall.coord_ini = coord(1:2);
                wall.coord_end = coord(3:4);
                
                % Store handle to wall object
                if (id <= length(drv.walls) && ~isempty(drv.walls(id).id))
                    fprintf(2,'Invalid numbering of walls: IDs cannot be repeated.\n');
                    status = 0; return;
                end
                drv.walls(id) = wall;
            end
            
            if (i < n)
                fprintf(2,'Invalid data in model parts file: Total number of WALLS.LINE2D is incompatible with provided data.\n');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsCircle(this,fid,drv)
            status = 1;
            
            if (drv.dimension == 3)
                fprintf(2,'Invalid data: WALLS.CIRCLE is only allowed in 2D models.\n');
                status = 0; return;
            end
            
            % Total number of circle walls
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                fprintf(2,'Invalid data in model parts file: Total number of WALLS.CIRCLE.\n');
                fprintf(2,'It must be a positive integer.\n');
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
                    fprintf(2,'Invalid data in model parts file: Number of parameters of WALLS.CIRCLE.\n');
                    fprintf(2,'It requires 4 parameters: ID, center coord X, center coord Y, radius.\n');
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    fprintf(2,'Invalid data in model parts file: ID number of WALLS.CIRCLE.\n');
                    fprintf(2,'It must be a positive integer.\n');
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~this.isDoubleArray(coord,2))
                    fprintf(2,'Invalid data in model parts file: Center coordinates of WALLS.CIRCLE with ID %d.\n',id);
                    fprintf(2,'It must be a pair of numeric values: X,Y.\n');
                    status = 0; return;
                end
                
                % Radius
                radius = values(4);
                if (~this.isDoubleArray(radius,1) || radius <= 0)
                    fprintf(2,'Invalid data in model parts file: Radius of WALLS.CIRCLE with ID %d.\n',id);
                    fprintf(2,'It must be a positive value.\n');
                    status = 0; return;
                end
                
                % Create new wall object
                wall        = Wall_Circle();
                wall.id     = id;
                wall.center = coord;
                wall.radius = radius;
                
                % Store handle to wall object
                if (id <= length(drv.walls) && ~isempty(drv.walls(id).id))
                    fprintf(2,'Invalid numbering of walls: IDs cannot be repeated.\n');
                    status = 0; return;
                end
                drv.walls(id) = wall;
            end
            
            if (i < n)
                fprintf(2,'Invalid data in model parts file: Total number of WALLS.CIRCLE is incompatible with provided data.\n');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readModelParts(this,fid,drv)
            status = 1;
            
            % Create ModelPart object
            mp = ModelPart();
            drv.n_mparts = drv.n_mparts + 1;
            drv.mparts(drv.n_mparts) = mp;
            
            % List of reserved names
            reserved = ['PARTICLES','WALLS'];
            
            % Model part name
            line = deblank(fgetl(fid));
            if (isempty(line) || isnumeric(line))
                fprintf(2,'Invalid data in model parts file: NAME of MODELPART was not provided or is invalid.\n');
                status = 0; return;
            end
            line = regexp(line,' ','split');
            if (length(line) ~= 2 || ~strcmp(line{1},'NAME') || ismember(line{2},reserved))
                fprintf(2,'Invalid data in model parts file: NAME of MODELPART was not provided or is invalid.\n');
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
                    fprintf(2,'Invalid data in model parts file: MODELPART can contain only two fields after its name, PARTICLES and WALLS.\n');
                    status = 0; return;
                elseif (length(line) ~= 2 || isnan(str2double(line{2})) || floor(str2double(line{2})) ~= ceil(str2double(line{2})) || str2double(line{2}) < 0)
                    fprintf(2,'Invalid data in model parts file: Number of %s of MODELPART %s was not provided correctly.\n',line{1},mp.name);
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
                        fprintf(2,'Invalid data in model parts file: Number of PARTICLES of MODELPART %s is not consistent with the provided IDs.\n',mp.name);
                        status = 0; return;
                    end

                    % Store handle to particle objects
                    for i = 1:np
                        id = particles(i);
                        if (floor(id) ~= ceil(id) || id <=0 || id > length(drv.particles))
                            fprintf(2,'Invalid data in model parts file: PARTICLES IDs of MODELPART %s is not consistent with existing particles.\n',mp.name);
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
                        fprintf(2,'Invalid data in model parts file: Number of WALLS of MODELPART %s is not consistent with the provided IDs.\n',mp.name);
                        status = 0; return;
                    end

                    % Store handle to walls objects
                    for i = 1:nw
                        id = walls(i);
                        if (floor(id) ~= ceil(id) || id <=0 || id > length(drv.walls))
                            fprintf(2,'Invalid data in model parts file: WALLS IDs of MODELPART %s is not consistent with existing walls.\n',mp.name);
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
                this.warn('Empty model part was created.');
            end
        end
    end
    
    %% Public methods: Interactions models
    methods
        %------------------------------------------------------------------
        function status = interactContactForceNormal(this,IM,drv)
            status = 1;
            if (~isfield(IM,'contact_force_normal') && drv.type == drv.THERMAL)
                return;
            elseif (~isfield(IM,'contact_force_normal') &&...
                   (drv.type == drv.MECHANICAL || drv.type == drv.THERMO_MECHANICAL))
                fprintf(2,'Missing data in project parameters file: InteractionModel.contact_force_normal.\n');
                status = 0; return;
            elseif (~isfield(IM.contact_force_normal,'model'))
                fprintf(2,'Missing data in project parameters file: InteractionModel.contact_force_normal.model.\n');
                status = 0; return;
            end
            cfn = string(IM.contact_force_normal.model);
            if (~this.isStringArray(cfn,1) ||...
               (~strcmp(cfn,'viscoelastic_linear')))
                fprintf(2,'Invalid data in project parameters file: InteractionModel.contact_force_normal.model.\n');
                fprintf(2,'Available options: viscoelastic_linear.\n');
                status = 0; return;
            end
            
            % Call sub-method for each type of model
            if (strcmp(cfn,'viscoelastic_linear'))
                if (~this.contactForceNormal_ViscoElasticLinear(IM.contact_force_normal,drv))
                    status = 0;
                    return;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = interactContactForceTangent(this,IM,drv)
            status = 1;
            if (~isfield(IM,'contact_force_tangent') && drv.type == drv.THERMAL)
                return;
            elseif (~isfield(IM,'contact_force_tangent') &&...
                   (drv.type == drv.MECHANICAL || drv.type == drv.THERMO_MECHANICAL))
                fprintf(2,'Missing data in project parameters file: InteractionModel.contact_force_tangent.\n');
                status = 0; return;
            elseif (~isfield(IM.contact_force_normal,'model'))
                fprintf(2,'Missing data in project parameters file: InteractionModel.contact_force_tangent.model.\n');
                status = 0; return;
            end
            cft = string(IM.contact_force_tangent.model);
            if (~this.isStringArray(cft,1) ||...
               (~strcmp(cft,'simple_spring')))
                fprintf(2,'Invalid data in project parameters file: InteractionModel.contact_force_tangent.model.\n');
                fprintf(2,'Available options: simple_spring.\n');
                status = 0; return;
            end
            
            % Call sub-method for each type of model
            if (strcmp(cft,'simple_spring'))
                if (~this.contactForceTangent_SimpleSpring(IM.contact_force_tangent,drv))
                    status = 0;
                    return;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = interactContactConduction(this,IM,drv)
            status = 1;
            if (~isfield(IM,'contact_conduction') && drv.type == drv.MECHANICAL)
                return;
            elseif (~isfield(IM,'contact_conduction') &&...
                   (drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL))
                this.warn('No model for contact thermal conduction was identified. This heat transfer mechanism will not be considered.');
                return;
            elseif (~isfield(IM.contact_force_normal,'model'))
                fprintf(2,'Missing data in project parameters file: InteractionModel.contact_conduction.model.\n');
                status = 0; return;
            end
            cc = string(IM.contact_conduction.model);
            if (~this.isStringArray(cc,1) ||...
               (~strcmp(cc,'batchelor_obrien')))
                fprintf(2,'Invalid data in project parameters file: InteractionModel.contact_conduction.model.\n');
                fprintf(2,'Available options: batchelor_obrien.\n');
                status = 0; return;
            end
            
            % Create object
            if (strcmp(cc,'batchelor_obrien'))
                drv.search.b_interact.contact_conduction = ContactConduction_BOB();
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceNormal_ViscoElasticLinear(this,CFN,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.contact_force_normal = ContactForceN_ViscoElasticLinear();
            
            % Stiffness formulation
            if (isfield(CFN,'stiff_coeff_formula'))
                if (~this.isStringArray(CFN.stiff_coeff_formula,1) ||...
                   (~strcmp(CFN.stiff_coeff_formula,'time')        &&...
                    ~strcmp(CFN.stiff_coeff_formula,'overlap')     &&...
                    ~strcmp(CFN.stiff_coeff_formula,'energy')))
                    fprintf(2,'Invalid data in project parameters file: InteractionModel.contact_force_normal.stiff_coeff_formula.\n');
                    fprintf(2,'Available options: time, overlap, energy.\n');
                    status = 0; return;
                end
                if (strcmp(CFN.stiff_coeff_formula,'time'))
                    drv.search.b_interact.contact_force_normal.stiff_formula =...
                    drv.search.b_interact.contact_force_normal.TIME;
                elseif (strcmp(CFN.stiff_coeff_formula,'overlap'))
                    drv.search.b_interact.contact_force_normal.stiff_formula =...
                    drv.search.b_interact.contact_force_normal.OVERLAP;
                elseif (strcmp(CFN.stiff_coeff_formula,'energy'))
                    drv.search.b_interact.contact_force_normal.stiff_formula =...
                    drv.search.b_interact.contact_force_normal.ENERGY;
                end
            end
            
            % Artificial cohesion
            if (isfield(CFN,'remove_artificial_cohesion'))
                if (~this.isLogicalArray(CFN.remove_artificial_cohesion,1))
                    fprintf(2,'Invalid data in project parameters file: InteractionModel.contact_force_normal.remove_artificial_cohesion.\n');
                    fprintf(2,'It must be a boolean: true or false.\n');
                    status = 0; return;
                end
                drv.search.b_interact.contact_force_normal.remove_cohesion =...
                CFN.remove_artificial_cohesion;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceTangent_SimpleSpring(this,CFN,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.contact_force_tangent = ContactForceT_Spring();
            
            % Spring coefficient
            if (isfield(CFN,'spring_coeff'))
                if (~this.isDoubleArray(CFN.spring_coeff,1))
                    fprintf(2,'Invalid data in project parameters file: InteractionModel.contact_force_tangent.spring_coeff.\n');
                    fprintf(2,'It must be a numeric value.\n');
                    status = 0; return;
                elseif (CFN.spring_coeff <= 0)
                    this.warn('Unphysical property value was found for InteractionModel.contact_force_tangent.spring_coeff');
                end
                drv.search.b_interact.contact_force_tangent.spring_coeff = CFN.spring_coeff;
            else
                fprintf(2,'Missing data in project parameters file: InteractionModel.contact_force_tangent.spring_coeff.\n');
                status = 0; return;
            end
        end
    end
    
    %% Public methods: Checks
    methods
        %------------------------------------------------------------------
        function status = checkDriver(~,drv)
            status = 1;
            if (isempty(drv.search))
                fprintf(2,'No search scheme was provided.');
                status = 0; return;
            end
            if ((drv.type == drv.THERMO_MECHANICAL || drv.type == drv.MECHANICAL) &&...
                (isempty(drv.scheme_vtrl) || isempty(drv.scheme_vrot)))
                fprintf(2,'No integration scheme for translational/rotational velocity was provided.');
                status = 0; return;
            end
            if ((drv.type == drv.THERMO_MECHANICAL || drv.type == drv.THERMAL) &&...
                 isempty(drv.scheme_temp))
                fprintf(2,'No integration scheme for temperature was provided.');
                status = 0; return;
            end
            if (isempty(drv.time_step))
                fprintf(2,'No time step was provided.');
                status = 0; return;
            end
            if (isempty(drv.max_time) && isempty(drv.max_step))
                fprintf(2,'No maximum time and steps were provided.');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = checkParticles(~,drv)
            status = 1;
            for i = 1:drv.n_particles
                p = drv.particles(i);
                if (isempty(p.radius))
                    fprintf(2,'No radius was provided to particle %d.',p.id);
                    status = 0; return;
                end
                if (isempty(p.material))
                    fprintf(2,'No material was provided to particle %d.',p.id);
                    status = 0; return;
                elseif (length(p.material) > 1)
                    fprintf(2,'More than one material was provided to particle %d.',p.id);
                    status = 0; return;
                end
                if ((drv.type == drv.THERMO_MECHANICAL || drv.type == drv.MECHANICAL) &&...
                    (isempty(p.material.density) ||...
                     isempty(p.material.young)   ||...
                     isempty(p.material.poisson) ||...
                     isempty(p.material.restitution)))
                    fprintf(2,'Missing mechanical properties of material %s.',p.material.name);
                    status = 0; return;
                elseif ((drv.type == drv.THERMO_MECHANICAL || drv.type == drv.THERMAL) &&...
                        (isempty(p.material.conduct) ||...
                         isempty(p.material.capacity)))
                    fprintf(2,'Missing thermal properties of material %s.',p.material.name);
                    status = 0; return;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = checkWalls(~,drv)
            status = 1;
            for i = 1:drv.n_walls
                w = drv.walls(i);
                if (w.type == w.LINE2D && isequal(w.coord_ini,w.coord_end))
                    fprintf(2,'Wall %d has no length.',w.id);
                    status = 0; return;
                end
            end
        end
    end
    
    %% Static methods: Auxiliary
    methods (Static)
        %------------------------------------------------------------------
        function warn(str)
            warning('off','backtrace');
            warning(str);
            warning('on','backtrace');
        end
        
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
            if (isa(variable,'char'))
                variable = string(variable);
            end
            if (isempty(variable) || length(variable) ~= size || (~isa(variable,'string')))
                is = false;
            else
                is = true;
            end
        end
        
        %------------------------------------------------------------------
        function [status,vals] = readTable(file,col)
            fid = fopen(file,'rt');
            if (fid < 0)
                fprintf(2,'Error opening values file.\n');
                fprintf(2,'It must have the same path of the project parameters file.\n');
                status = 0; return;
            end
            vals = fscanf(fid,'%f',[col Inf])';
            fclose(fid);
            status = 1;
        end
    end
end