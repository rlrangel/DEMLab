%% Read class
%
%% Description
%
% This is a handle class responsible for reading the paremeters and model
% parts files, building the simulation objects, and checking the
% input data.
%
% Two files are read for running a simulation:
%
% * _json_ file with the *project parameters*
%
% * _txt_ file with the *model parts*
%
% In addition, it identifies if there exists a storage file with the same
% name of the problem name. If so, the simulation is restarted from the
% stored results.
%
classdef Read < handle
    %% Constructor method
    methods
        function this = Read()
            
        end
    end
    
    %% Public methods: main functions
    methods
        %------------------------------------------------------------------
        function [status,drv,storage] = execute(this,path,fid)
            drv     = [];
            storage = [];
            
            % Parse json file
            file_txt = char(fread(fid,inf)');
            fclose(fid);
            if (isempty(file_txt))
                fprintf(2,'Empty project parameters file.\n');
                status = 0; return;
            end
            try
                json = jsondecode(file_txt);
            catch ME
                fprintf(2,'Error reading the project parameters file:\n');
                fprintf(2,strcat(ME.message,'\n'));
                status = 0; return;
            end
            
            % Get problem name
            [status,name] = this.getName(json);
            
            % Look for storage file to continue analysis from previous stage
            if (status)
                storage = fullfile(path,strcat(name,'.mat'));
                if (exist(storage,'file') == 2)
                    status = 2;
                    return;
                end
            end
            
            % Feed simulation data
            if (status)
                [status,drv,model_parts_file] = this.getProblemData(json,path,name);
            end
            if (status)
                status = this.getModelParts(drv,model_parts_file);
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
                status = this.getPrescribedCondition(json,drv);
            end
            if (status)
                status = this.getFixedCondition(json,drv);
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
            if (status)
                status = this.getOutput(json,drv);
            end
            if (status)
                status = this.getGraph(json,drv);
            end
            if (status)
                status = this.getAnimation(json,drv);
            end
        end
        
        %------------------------------------------------------------------
        function status = check(this,drv)
            status = 1;
            if (status)
                status = this.checkDriver(drv);
            end
            if (status)
                status = this.checkMaterials(drv);
            end
            if (status)
                status = this.checkParticles(drv);
            end
            if (status)
                status = this.checkWalls(drv);
            end
            if (status)
                status = this.checkModels(drv);
            end
        end
    end
    
    %% Public methods: project parameters file
    methods
        %------------------------------------------------------------------
        function [status,name] = getName(this,json)
            status = 1;
            
            % Check if name exists
            if (~isfield(json,'ProblemData'))
                this.missingDataError('ProblemData parameters');
                status = 0; return;
            elseif (~isfield(json.ProblemData,'name'))
                this.missingDataError('ProblemData.name');
                status = 0; return;
            end
            
            % Get name
            name = string(json.ProblemData.name);
            if (~this.isStringArray(name,1) || length(split(name)) > 1)
                this.invalidParamError('ProblemData.name','It must be a string with no spaces');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function [status,drv,model_parts_file] = getProblemData(this,json,path,name)
            status = 1;
            drv = [];
            model_parts_file = [];
            
            % Check if all fields exist
            PD = json.ProblemData;
            if (~isfield(PD,'analysis_type') || ~isfield(PD,'model_parts_file'))
                this.missingDataError('ProblemData.analysis_type and/or ProblemData.model_parts_file');
                status = 0; return;
            end
            
            % Create object of Driver class
            anl = string(PD.analysis_type);
            if (~this.isStringArray(anl,1) ||...
               (~strcmp(anl,'mechanical') && ~strcmp(anl,'thermal') && ~strcmp(anl,'thermo_mechanical')))
                this.invalidOptError('ProblemData.analysis_type','mechanical, thermal, thermo_mechanical');
                status = 0; return;
            elseif (strcmp(anl,'mechanical'))
                drv = Driver_Mechanical();
            elseif (strcmp(anl,'thermal'))
                drv = Driver_Thermal();
            elseif (strcmp(anl,'thermo_mechanical'))
                drv = Driver_ThermoMechanical();
            end
            
            % Set path to model folder and name
            drv.path = path;
            drv.name = name;
            
            % Model parts file name
            model_parts_file = string(PD.model_parts_file);
            if (~this.isStringArray(model_parts_file,1))
                this.invalidParamError('ProblemData.model_parts_file','It must be a string with the model part file name');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = getModelParts(this,drv,file)
            status = 1;
            
            % Open model parts file
            fullname = fullfile(drv.path,file);
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
                    case '%PARTICLES.SPHERE'
                        status = this.readParticlesSphere(fid,drv);
                    case '%PARTICLES.CYLINDER'
                        status = this.readParticlesCylinder(fid,drv);
                    case '%WALLS.LINE'
                        status = this.readWallsLine(fid,drv);
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
                this.invalidModelError('Model has no particle.',[]);
                status = 0; return;
            elseif (drv.particles(drv.n_particles).id > drv.n_particles)
                this.invalidModelError('Particles IDs cannot skip numbers.',[]);
                status = 0; return;
            end
            if (drv.n_walls > 0 && drv.walls(drv.n_walls).id > drv.n_walls)
                this.invalidModelError('Walls IDs cannot skip numbers.',[]);
                status = 0; return;
            end
            for i = 1:drv.n_mparts
                if (length(findobj(drv.mparts,'name',drv.mparts(i).name)) > 1)
                    this.invalidModelError('Repeated model part name.',[]);
                    status = 0; return;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getSolverParam(this,json,drv)
            status = 1;
            if (~isfield(json,'Solver'))
                this.missingDataError('Solver parameters');
                status = 0; return;
            end
            
            % Automatic time step
            if (isfield(json.Solver,'auto_time_step'))
                if (~this.isLogicalArray(json.Solver.auto_time_step,1))
                    this.invalidParamError('Solver.auto_time_step','It must be a boolean: true or false');
                    status = 0; return;
                end
                drv.auto_step = true;
            end
            
            % Time step
            if (isfield(json.Solver,'time_step'))
                if (~this.isDoubleArray(json.Solver.time_step,1) || json.Solver.time_step <= 0)
                    this.invalidParamError('Solver.time_step','It must be a positive value');
                    status = 0; return;
                end
                drv.time_step = json.Solver.time_step;
                if (drv.auto_step)
                    this.warnMsg('Automatic time step was selected, so the time step value will be ignored.');
                end
            elseif (~isfield(json.Solver,'auto_time_step'))
                drv.auto_step = true;
                this.warnMsg('Time step was not provided, an automatic time step will be used.');
            elseif (~drv.auto_step)
                this.missingDataError('Solver.time_step');
                status = 0; return;
            end
            
            % Final time
            if (isfield(json.Solver,'final_time'))
                if (~this.isDoubleArray(json.Solver.final_time,1) || json.Solver.final_time <= 0)
                    this.invalidParamError('Solver.final_time','It must be a positive value');
                    status = 0; return;
                end
                drv.max_time = json.Solver.final_time;
            elseif (~isfield(json.Solver,'max_steps'))
                this.missingDataError('Solver.final_time or Solver.max_steps');
                status = 0; return;
            end
            
            % Maximum steps
            if (isfield(json.Solver,'max_steps'))
                if (~this.isIntArray(json.Solver.max_steps,1) || json.Solver.max_steps <= 0)
                    this.invalidParamError('Solver.max_steps','It must be a positive integer');
                    status = 0; return;
                end
                drv.max_step = json.Solver.max_steps;
            elseif (~isfield(json.Solver,'final_time'))
                this.missingDataError('Solver.final_time or Solver.max_steps');
                status = 0; return;
            end
            
            % Time integration scheme: translational velocity
            if ((drv.type == drv.MECHANICAL || drv.type == drv.THERMO_MECHANICAL) && isfield(json.Solver,'integr_scheme_trans'))
                scheme = string(json.Solver.integr_scheme_trans);
                if (~this.isStringArray(scheme,1)    ||...
                    ~strcmp(scheme,'forward_euler')  &&...
                    ~strcmp(scheme,'modified_euler') &&...
                    ~strcmp(scheme,'taylor_2'))
                    this.invalidOptError('Solver.integr_scheme_trans','forward_euler, modified_euler, taylor_2');
                    status = 0; return;
                end
                if (strcmp(scheme,'forward_euler'))
                    drv.scheme_trl = Scheme_EulerForward();
                elseif (strcmp(scheme,'modified_euler'))
                    drv.scheme_trl = Scheme_EulerMod();
                elseif (strcmp(scheme,'taylor_2'))
                    drv.scheme_trl = Scheme_Taylor2();
                end
            end
            
            % Time integration scheme: rotational velocity
            if ((drv.type == drv.MECHANICAL || drv.type == drv.THERMO_MECHANICAL) && isfield(json.Solver,'integr_scheme_rotat'))
                scheme = string(json.Solver.integr_scheme_rotat);
                if (~this.isStringArray(scheme,1)    ||...
                    ~strcmp(scheme,'forward_euler')  &&...
                    ~strcmp(scheme,'modified_euler') &&...
                    ~strcmp(scheme,'taylor_2'))
                    this.invalidOptError('Solver.integr_scheme_rotat','forward_euler, modified_euler, taylor_2');
                    status = 0; return;
                end
                if (strcmp(scheme,'forward_euler'))
                    drv.scheme_rot = Scheme_EulerForward();
                elseif (strcmp(scheme,'modified_euler'))
                    drv.scheme_rot = Scheme_EulerMod();
                elseif (strcmp(scheme,'taylor_2'))
                    drv.scheme_rot = Scheme_Taylor2();
                end
            end
            
            % Time integration scheme: temperature
            if ((drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL) && isfield(json.Solver,'integr_scheme_therm'))
                scheme = string(json.Solver.integr_scheme_therm);
                if (~this.isStringArray(scheme,1) ||...
                    ~strcmp(scheme,'forward_euler'))
                    this.invalidOptError('Solver.integr_scheme_therm','forward_euler');
                    status = 0; return;
                end
                if (strcmp(scheme,'forward_euler'))
                    drv.scheme_temp = Scheme_EulerForward();
                end
            end
            
            % Forcing terms evaluation frequency
            if (isfield(json.Solver,'eval_frequency'))
                if (~this.isIntArray(json.Solver.eval_frequency,1) || json.Solver.eval_frequency <= 0)
                    this.invalidParamError('Solver.eval_frequency','It must be a positive integer');
                    status = 0; return;
                end
                if (drv.type == drv.THERMAL)
                    this.warnMsg('Solver.eval_frequency is not available for thermal analysis. It will be ignored.');
                else
                    drv.eval_freq = json.Solver.eval_frequency;
                end
            end
            
            % Paralelization
            if (isfield(json.Solver,'parallelization'))
                if (~this.isLogicalArray(json.Solver.parallelization,1))
                    this.invalidParamError('Solver.parallelization','It must be a boolean: true or false');
                    status = 0; return;
                end
                drv.parallel = json.Solver.parallelization;
            end
            
            % Number of workers
            if (isfield(json.Solver,'workers'))
                if (~this.isIntArray(json.Solver.workers,1) || json.Solver.workers <= 0)
                    this.invalidParamError('Solver.workers','It must be a positive integer');
                    status = 0; return;
                end
                drv.workers = json.Solver.workers;
            end
        end
        
        %------------------------------------------------------------------
        function status = getSearch(this,json,drv)
            status = 1;
            if (~isfield(json,'Search'))
                return;
            end
            
            % Scheme
            if (~isfield(json.Search,'scheme'))
                this.missingDataError('Search.scheme');
                status = 0; return;
            end
            scheme = string(Search.scheme);
            if (~this.isStringArray(scheme,1) ||...
               (~strcmp(scheme,'simple_loop') &&...
                ~strcmp(scheme,'verlet_list')))
                this.invalidOptError('Search.scheme','simple_loop, verlet_list');
                status = 0; return;
                
            elseif (strcmp(scheme,'simple_loop'))
                drv.search = Search_SimpleLoop();
                
                % Search frequency
                if (isfield(json.Search,'search_frequency'))
                    if (~this.isIntArray(json.Search.search_frequency,1) || json.Search.search_frequency <= 0)
                        this.invalidParamError('Search.search_frequency','It must be a positive integer');
                        status = 0; return;
                    end
                    drv.search.freq = json.Search.search_frequency;
                end

            elseif (strcmp(scheme,'verlet_list'))
                drv.search = Search_VerletList();
                
                % Search frequency
                if (isfield(json.Search,'search_frequency'))
                    if (~this.isIntArray(json.Search.search_frequency,1) || json.Search.search_frequency <= 0)
                        this.invalidParamError('Search.search_frequency','It must be a positive integer');
                        status = 0; return;
                    end
                    drv.search.freq = json.Search.search_frequency;
                end
                
                % Verlet list update frequency
                if (isfield(json.Search,'verlet_frequency'))
                    if (~this.isIntArray(json.Search.verlet_frequency,1) || json.Search.verlet_frequency < drv.search.freq)
                        this.invalidParamError('Search.verlet_frequency','It must be greater than the search frequency');
                        status = 0; return;
                    end
                    drv.search.verlet_freq = json.Search.verlet_frequency;
                else
                    drv.search.verlet_freq = 10 * drv.search.freq;
                end
                
                % Verlet distance
                if (isfield(json.Search,'verlet_distance'))
                    if (~this.isDoubleArray(json.Search.verlet_distance,1) || json.Search.verlet_distance <= 0)
                        this.invalidParamError('Search.verlet_distance','It must be a positive value');
                        status = 0; return;
                    end
                    drv.search.verlet_dist = json.Search.verlet_distance;
                else
                    Rmax = max([drv.particles.radius]);
                    drv.search.verlet_dist = 5*Rmax;
                end
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
                this.missingDataError('BoundingBox.shape');
                status = 0; return;
            end
            shape = string(BB.shape);
            if (~this.isStringArray(shape,1))
                this.invalidParamError('BoundingBox.shape','It must be a pre-defined string of the bounding box shape');
                status = 0; return;
            end
            
            % RECTANGLE
            if (strcmp(shape,'rectangle'))
                warn = 0;
                
                % Minimum limits
                if (isfield(BB,'limit_min'))
                    limit_min = BB.limit_min;
                    if (~this.isDoubleArray(limit_min,2))
                        this.invalidParamError('BoundingBox.limit_min','It must be a pair of numeric values with X,Y coordinates of bottom-left corner');
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
                        this.invalidParamError('BoundingBox.limit_max','It must be a pair of numeric values with X,Y coordinates of top-right corner');
                        status = 0; return;
                    end
                else
                    limit_max = [inf;inf];
                    warn = warn + 2;
                end
                
                % Check consistency
                if (warn == 1)
                    this.warnMsg('Minimum limits of bounding box were not provided. Infinite limits will be assumed.');
                elseif (warn == 2)
                    this.warnMsg('Maximum limits of bounding box were not provided. Infinite limits will be assumed.');
                elseif (warn == 3)
                    this.warnMsg('Maximum and minimum limits of bounding box were not provided. Bounding box will not be considered.');
                    return;
                end
                if (limit_min(1) >= limit_max(1) || limit_min(2) >= limit_max(2))
                    this.invalidParamError('BoundingBox.limit_min or BoundingBox.limit_max','The minimum coordinates must be smaller than the maximum ones');
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
                    this.missingDataError('BoundingBox.center and/or BoundingBox.radius');
                    status = 0; return;
                end
                center = BB.center;
                radius = BB.radius;
                
                % Center
                if (~this.isDoubleArray(center,2))
                    this.invalidParamError('BoundingBox.center','It must be a pair of numeric values with X,Y coordinates of center point');
                    status = 0; return;
                end
                
                % Radius
                if (~this.isDoubleArray(radius,1) || radius <= 0)
                    this.invalidParamError('BoundingBox.radius','It must be a positive value');
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
                    this.missingDataError('BoundingBox.points_x and/or BoundingBox.points_y');
                    status = 0; return;
                end
                x = BB.points_x;
                y = BB.points_y;
                
                % points_x / points_y
                if (~this.isDoubleArray(x,length(x)) || ~this.isDoubleArray(y,length(y)) || length(x) ~= length(y))
                    this.invalidParamError('BoundingBox.points_x and/or BoundingBox.points_y','It must be lists of numeric values with the X or Y coordinates of polygon points');
                    status = 0; return;
                end
                
                % Check for valid polygon
                warning off MATLAB:polyshape:repairedBySimplify;
                warning off MATLAB:polyshape:boolOperationFailed
                try
                    p = polyshape(x,y);
                catch
                    this.invalidParamError('BoundingBox.points_x and/or BoundingBox.points_y','Inconsistent polygon shape');
                    status = 0; return;
                end
                if (p.NumRegions ~= 1)
                    this.invalidParamError('BoundingBox.points_x and/or BoundingBox.points_y','Inconsistent polygon shape');
                    status = 0; return;
                end
                
                % Create object and set properties
                bbox = BBox_Polygon();
                bbox.coord_x = x;
                bbox.coord_y = y;
                drv.bbox = bbox;
            else
                this.invalidOptError('BoundingBox.shape','rectangle, circle, polygon');
                status = 0; return;
            end
            
            % Interval
            if (isfield(BB,'interval'))
                interval = BB.interval;
                if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                    this.invalidParamError('BoundingBox.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
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
                    this.missingDataError('Sink.shape');
                    status = 0; return;
                end
                shape = string(S.shape);
                if (~this.isStringArray(shape,1))
                    this.invalidParamError('Sink.shape','It must be a pre-defined string of the sink shape');
                    status = 0; return;
                end
                
                % RECTANGLE
                if (strcmp(shape,'rectangle'))
                    if (~isfield(S,'limit_min') || ~isfield(S,'limit_max'))
                        this.missingDataError('Sink.limit_min and/or Sink.limit_max');
                        status = 0; return;
                    end
                    limit_min = S.limit_min;
                    limit_max = S.limit_max;
                    
                    % Minimum limits
                    if (~this.isDoubleArray(limit_min,2))
                        this.invalidParamError('Sink.limit_min','It must be a pair of numeric values with X,Y coordinates of bottom-left corner');
                        status = 0; return;
                    end
                    
                    % Maximum limits
                    if (~this.isDoubleArray(limit_max,2))
                        this.invalidParamError('Sink.limit_max','It must be a pair of numeric values with X,Y coordinates of top-right corner');
                        status = 0; return;
                    end
                    
                    % Check consistency
                    if (limit_min(1) >= limit_max(1) || limit_min(2) >= limit_max(2))
                        this.invalidParamError('Sink.limit_min or Sink.limit_max','The minimum coordinates must be smaller than the maximum ones');
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
                        this.missingDataError('Sink.center and/or Sink.radius');
                        status = 0; return;
                    end
                    center = S.center;
                    radius = S.radius;
                    
                    % Center
                    if (~this.isDoubleArray(center,2))
                        this.invalidParamError('Sink.center','It must be a pair of numeric values with X,Y coordinates of center point');
                        status = 0; return;
                    end
                    
                    % Radius
                    if (~this.isDoubleArray(radius,1) || radius <= 0)
                        this.invalidParamError('Sink.radius','It must be a positive value');
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
                        this.missingDataError('Sink.points_x and/or Sink.points_y');
                        status = 0; return;
                    end
                    x = S.points_x;
                    y = S.points_y;
                    
                    % points_x / points_y
                    if (~this.isDoubleArray(x,length(x)) || ~this.isDoubleArray(y,length(y)) || length(x) ~= length(y))
                        this.invalidParamError('Sink.points_x and/or Sink.points_y','It must be lists of numeric values with the X or Y coordinates of polygon points');
                        status = 0; return;
                    end
                    
                    % Check for valid polygon
                    warning off MATLAB:polyshape:repairedBySimplify;
                    warning off MATLAB:polyshape:boolOperationFailed
                    try
                        p = polyshape(x,y);
                    catch
                        this.invalidParamError('Sink.points_x and/or Sink.points_y','Inconsistent polygon shape');
                        status = 0; return;
                    end
                    if (p.NumRegions ~= 1)
                        this.invalidParamError('Sink.points_x and/or Sink.points_y','Inconsistent polygon shape');
                        status = 0; return;
                    end
                    
                    % Create object and set properties
                    sink = Sink_Polygon();
                    sink.coord_x = x;
                    sink.coord_y = y;
                    drv.sink = sink;
                    
                else
                    this.invalidOptError('Sink.shape','rectangle, circle, polygon');
                    status = 0; return;
                end
                
                % Interval
                if (isfield(S,'interval'))
                    interval = S.interval;
                    if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                        this.invalidParamError('Sink.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
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
                    this.invalidParamError('GlobalCondition.gravity','It must be a pair of numeric values with X,Y gravity acceleration components');
                    status = 0; return;
                end
                drv.gravity = g;
            end
            
            % Damping
            if (isfield(GC,'damping_translation'))
                dt = GC.damping_translation;
                if (~this.isDoubleArray(dt,1))
                    this.invalidParamError('GlobalCondition.damping_translation','It must be a numeric value');
                    status = 0; return;
                end
                drv.damp_trl = dt;
            end
            if (isfield(GC,'damping_rotation'))
                dr = GC.damping_rotation;
                if (~this.isDoubleArray(dr,1))
                    this.invalidParamError('GlobalCondition.damping_rotation','It must be a numeric value');
                    status = 0; return;
                end
                drv.damp_rot = dr;
            end
            
            % Interstitial fluid properties
            if (isfield(GC,'fluid_thermal_conductivity'))
                fc = GC.fluid_thermal_conductivity;
                if (~this.isDoubleArray(fc,1))
                    this.invalidParamError('GlobalCondition.fluid_thermal_conductivity','It must be a numeric value');
                    status = 0; return;
                elseif (fc <= 0)
                    this.warnMsg('Unphysical value found for interstitial fluid property.');
                end
                drv.fluid_conduct = fc;
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
                if (~strcmp(f,'translational_velocity') &&...
                    ~strcmp(f,'rotational_velocity')    &&...
                    ~strcmp(f,'temperature'))
                    this.warnMsg('A nonexistent field was identified in InitialCondition. It will be ignored.');
                end
            end
            
            % TRANSLATIONAL VELOCITY
            if (isfield(IC,'translational_velocity'))
                for i = 1:length(IC.translational_velocity)
                    TV = IC.translational_velocity(i);
                    if (~isfield(TV,'value') || ~isfield(TV,'model_parts'))
                        this.missingDataError('InitialCondition.translational_velocity.value and/or InitialCondition.translational_velocity.model_parts');
                        status = 0; return;
                    end
                    
                    % Velocity value
                    val = TV.value;
                    if (~this.isDoubleArray(val,2))
                        this.invalidParamError('InitialCondition.translational_velocity.value','It must be a pair of numeric values with X,Y velocity components');
                        status = 0; return;
                    end
                    
                    % Apply initial velocity to selected particles
                    model_parts = string(TV.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('InitialCondition.translational_velocity.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.veloc_trl] = deal(val);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in InitialCondition.translational_velocity.');
                                continue;
                            end
                            [mp.particles.veloc_trl] = deal(val);
                        end
                    end
                end
            end
            
            % ROTATIONAL VELOCITY
            if (isfield(IC,'rotational_velocity'))                
                for i = 1:length(IC.rotational_velocity)
                    RV = IC.rotational_velocity(i);
                    if (~isfield(RV,'value') || ~isfield(RV,'model_parts'))
                        this.missingDataError('InitialCondition.rotational_velocity.value and/or InitialCondition.rotational_velocity.model_parts');
                        status = 0; return;
                    end
                    
                    % Velocity value
                    val = RV.value;
                    if (~this.isDoubleArray(val,1))
                        this.invalidParamError('InitialCondition.rotational_velocity.value','It must be a numeric value');
                        status = 0; return;
                    end
                    
                    % Apply initial velocity to selected particles
                    model_parts = string(RV.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('InitialCondition.rotational_velocity.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.veloc_rot] = deal(val);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in InitialCondition.rotational_velocity.');
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
                        this.missingDataError('InitialCondition.temperature.value and/or InitialCondition.temperature.model_parts');
                        status = 0; return;
                    end
                    
                    % Temperature value
                    val = T.value;
                    if (~this.isDoubleArray(val,1))
                        this.invalidParamError('InitialCondition.temperature.value','It must be a numeric value');
                        status = 0; return;
                    end
                    
                    % Apply initial temperature to selected elements
                    model_parts = string(T.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('InitialCondition.temperature.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.temperature] = deal(val);
                        elseif (strcmp(name,'WALLS'))
                            [drv.walls.temperature] = deal(val);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in InitialCondition.temperature.');
                                continue;
                            end
                            [mp.particles.temperature] = deal(val);
                            [mp.walls.temperature]     = deal(val);
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getPrescribedCondition(this,json,drv)
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
                    this.warnMsg('A nonexistent field was identified in PrescribedCondition. It will be ignored.');
                end
            end
            
            % In the following, the types of conditions have very similar codes
            
            % FORCE
            if (isfield(PC,'force'))
                for i = 1:length(PC.force)
                    F = PC.force(i);
                    if (~isfield(F,'type') || ~isfield(F,'model_parts'))
                        this.missingDataError('PrescribedCondition.force.type and/or PrescribedCondition.force.model_parts');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(F.type);
                    if (~this.isStringArray(type,1))
                        this.invalidParamError('PrescribedCondition.force.type','It must be a pre-defined string of the condition type');
                        status = 0; return;
                        
                    elseif (strcmp(type,'constant'))
                        % Create object
                        pc = Condition_Constant();
                        
                        % Value
                        if (~isfield(F,'value'))
                            this.missingDataError('PrescribedCondition.force.value');
                            status = 0; return;
                        end
                        val = F.value;
                        if (~this.isDoubleArray(val,2))
                            this.invalidParamError('PrescribedCondition.force.value','It must be a pair of numeric values with X,Y force components');
                            status = 0; return;
                        end
                        pc.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        pc = Condition_Linear();
                        
                        % Initial value
                        if (isfield(F,'initial_value'))
                            val = F.initial_value;
                            if (~this.isDoubleArray(val,2))
                                this.invalidParamError('PrescribedCondition.force.initial_value','It must be a pair of numeric values with X,Y force components');
                                status = 0; return;
                            end
                            pc.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(F,'slope'))
                            this.missingDataError('PrescribedCondition.force.slope');
                            status = 0; return;
                        end
                        slope = F.slope;
                        if (~this.isDoubleArray(slope,2))
                            this.invalidParamError('PrescribedCondition.force.slope','It must be a pair of numeric values with X,Y components of change rate');
                            status = 0; return;
                        end
                        pc.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        pc = Condition_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(F,'base_value') || ~isfield(F,'amplitude') || ~isfield(F,'period'))
                            this.missingDataError('PrescribedCondition.force.base_value and/or PrescribedCondition.force.amplitude and/or PrescribedCondition.force.period');
                            status = 0; return;
                        end
                        val       = F.base_value;
                        amplitude = F.amplitude;
                        period    = F.period;
                        if (~this.isDoubleArray(val,2))
                            this.invalidParamError('PrescribedCondition.force.base_value','It must be a pair of numeric values with X,Y force components');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,2) || any(amplitude < 0))
                            this.invalidParamError('PrescribedCondition.force.amplitude','It must be a pair of positive values with X,Y force components');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            this.invalidParamError('PrescribedCondition.force.period','It must be a positive value with the period of oscillation');
                            status = 0; return;
                        end
                        pc.base_value = val;
                        pc.amplitude  = amplitude;
                        pc.period     = period;
                        
                        % Shift
                        if (isfield(F,'shift'))
                            shift = F.shift;
                            if (~this.isDoubleArray(shift,1))
                                this.invalidParamError('PrescribedCondition.force.shift','It must be a numeric value with the shift of the oscillation');
                                status = 0; return;
                            end
                            pc.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        pc = Condition_Table();
                        
                        % Table values
                        if (isfield(F,'values'))
                            vals = F.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                this.invalidParamError('PrescribedCondition.force.values','It must be a numeric table with the first row as the independent variable values and the others as the dependent variable values');
                                status = 0; return;
                            end
                        elseif (isfield(F,'file'))
                            file = F.file;
                            if (~this.isStringArray(file,1))
                                this.invalidParamError('PrescribedCondition.force.file','It must be a string with the file name');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(drv.path,file),3);
                            if (status == 0)
                                return;
                            end
                        else
                            this.missingDataError('PrescribedCondition.force.values or PrescribedCondition.force.file');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 3)
                            this.invalidParamError('PrescribedCondition.force.values','It must contain 3 columns (one for the independent variable values and two for the X,Y force components), and at least 2 points');
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
                                this.invalidOptError('PrescribedCondition.force.interpolation','linear, makima, cubic, pchip or spline');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(pc.val_x,1) < 2)
                                    this.invalidParamError('PrescribedCondition.force.values','It must contain at least 2 points for linear interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(pc.val_x,1) < 2)
                                    this.invalidParamError('PrescribedCondition.force.values','It must contain at least 2 points for makima interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(pc.val_x,1) < 3)
                                    this.invalidParamError('PrescribedCondition.force.values','It must contain at least 3 points for cubic interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(pc.val_x,1) < 4)
                                    this.invalidParamError('PrescribedCondition.force.values','It must contain at least 4 points for pchip interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(pc.val_x,1) < 4)
                                    this.invalidParamError('PrescribedCondition.force.values','It must contain at least 4 points for spline interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_SPLINE;
                            end
                        end
                    else
                        this.invalidOptError('PrescribedCondition.force.type','constant, linear, oscillatory, table');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(F,'interval'))
                        interval = F.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            this.invalidParamError('PrescribedCondition.force.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
                            status = 0; return;
                        end
                        pc.interval  = interval;
                        pc.init_time = min(0,min(interval));
                    else
                        pc.init_time = 0;
                    end
                    
                    % Add handle to prescribed condition to selected particles
                    model_parts = string(F.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('PrescribedCondition.force.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.pc_force] = deal(pc);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in PrescribedCondition.force.');
                                continue;
                            end
                            [mp.particles.pc_force] = deal(pc);
                        end
                    end
                end
            end
            
            % TORQUE
            if (isfield(PC,'torque'))
                for i = 1:length(PC.torque)
                    T = PC.torque(i);
                    if (~isfield(T,'type') || ~isfield(T,'model_parts'))
                        this.missingDataError('PrescribedCondition.torque.type and/or PrescribedCondition.torque.model_parts');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(T.type);
                    if (~this.isStringArray(type,1))
                        this.invalidParamError('PrescribedCondition.torque.type','It must be a pre-defined string of the condition type');
                        status = 0; return;
                        
                    elseif (strcmp(type,'constant'))
                        % Create object
                        pc = Condition_Constant();
                        
                        % Value
                        if (~isfield(T,'value'))
                            this.missingDataError('PrescribedCondition.torque.value');
                            status = 0; return;
                        end
                        val = T.value;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('PrescribedCondition.torque.value','It must be a numeric value');
                            status = 0; return;
                        end
                        pc.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        pc = Condition_Linear();
                        
                        % Initial value
                        if (isfield(T,'initial_value'))
                            val = T.initial_value;
                            if (~this.isDoubleArray(val,1))
                                this.invalidParamError('PrescribedCondition.torque.initial_value','It must be a numeric value');
                                status = 0; return;
                            end
                            pc.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(T,'slope'))
                            this.missingDataError('PrescribedCondition.torque.slope');
                            status = 0; return;
                        end
                        slope = T.slope;
                        if (~this.isDoubleArray(slope,1))
                            this.invalidParamError('PrescribedCondition.torque.slope','It must be a numeric value');
                            status = 0; return;
                        end
                        pc.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        pc = Condition_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(T,'base_value') || ~isfield(T,'amplitude') || ~isfield(T,'period'))
                            this.missingDataError('PrescribedCondition.torque.base_value and/or PrescribedCondition.torque.amplitude and/or PrescribedCondition.torque.period');
                            status = 0; return;
                        end
                        val       = T.base_value;
                        amplitude = T.amplitude;
                        period    = T.period;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('PrescribedCondition.torque.base_value','It must be a numeric value');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,1) || amplitude < 0)
                            this.invalidParamError('PrescribedCondition.torque.amplitude','It must be a positive value with the amplitude of oscillation');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            this.invalidParamError('PrescribedCondition.torque.period','It must be a positive value with the period of oscillation');
                            status = 0; return;
                        end
                        pc.base_value = val;
                        pc.amplitude  = amplitude;
                        pc.period     = period;
                        
                        % Shift
                        if (isfield(T,'shift'))
                            shift = T.shift;
                            if (~this.isDoubleArray(shift,1))
                                this.invalidParamError('PrescribedCondition.torque.shift','It must be a numeric value with the shift of the oscillation');
                                status = 0; return;
                            end
                            pc.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        pc = Condition_Table();
                        
                        % Table values
                        if (isfield(T,'values'))
                            vals = T.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                this.invalidParamError('PrescribedCondition.torque.values','It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values');
                                status = 0; return;
                            end
                        elseif (isfield(T,'file'))
                            file = T.file;
                            if (~this.isStringArray(file,1))
                                this.invalidParamError('PrescribedCondition.torque.file','It must be a string with the file name');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(drv.path,file),2);
                            if (status == 0)
                                return;
                            end
                        else
                            this.missingDataError('PrescribedCondition.torque.values or PrescribedCondition.torque.file');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 2)
                            this.invalidParamError('PrescribedCondition.torque.values','It must contain 2 columns (one for the independent variable values and another for the torque values), and at least 2 points');
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
                                this.invalidOptError('PrescribedCondition.torque.interpolation','linear, makima, cubic, pchip or spline');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(pc.val_x,1) < 2)
                                    this.invalidParamError('PrescribedCondition.torque.values','It must contain at least 2 points for linear interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(pc.val_x,1) < 2)
                                    this.invalidParamError('PrescribedCondition.torque.values','It must contain at least 2 points for makima interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(pc.val_x,1) < 3)
                                    this.invalidParamError('PrescribedCondition.torque.values','It must contain at least 3 points for cubic interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(pc.val_x,1) < 4)
                                    this.invalidParamError('PrescribedCondition.torque.values','It must contain at least 4 points for pchip interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(pc.val_x,1) < 4)
                                    this.invalidParamError('PrescribedCondition.torque.values','It must contain at least 4 points for spline interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_SPLINE;
                            end
                        end
                    else
                        this.invalidOptError('PrescribedCondition.torque.type','constant, linear, oscillatory, table');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(T,'interval'))
                        interval = T.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            this.invalidParamError('PrescribedCondition.torque.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
                            status = 0; return;
                        end
                        pc.interval  = interval;
                        pc.init_time = min(0,min(interval));
                    else
                        pc.init_time = 0;
                    end
                    
                    % Add handle to prescribed condition to selected particles
                    model_parts = string(T.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('PrescribedCondition.torque.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.pc_torque] = deal(pc);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in PrescribedCondition.torque.');
                                continue;
                            end
                            [mp.particles.pc_torque] = deal(pc);
                        end
                    end
                end
            end
            
            % HEAT FLUX
            if (isfield(PC,'heat_flux'))
                for i = 1:length(PC.heat_flux)
                    HF = PC.heat_flux(i);
                    if (~isfield(HF,'type') || ~isfield(HF,'model_parts'))
                        this.missingDataError('PrescribedCondition.heat_flux.type and/or PrescribedCondition.heat_flux.model_parts');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(HF.type);
                    if (~this.isStringArray(type,1))
                        this.invalidParamError('PrescribedCondition.heat_flux.type','It must be a pre-defined string of the condition type');
                        status = 0; return;
                        
                    elseif (strcmp(type,'constant'))
                        % Create object
                        pc = Condition_Constant();
                        
                        % Value
                        if (~isfield(HF,'value'))
                            this.missingDataError('PrescribedCondition.heat_flux.value');
                            status = 0; return;
                        end
                        val = HF.value;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('PrescribedCondition.heat_flux.value','It must be a numeric value');
                            status = 0; return;
                        end
                        pc.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        pc = Condition_Linear();
                        
                        % Initial value
                        if (isfield(HF,'initial_value'))
                            val = HF.initial_value;
                            if (~this.isDoubleArray(val,1))
                                this.invalidParamError('PrescribedCondition.heat_flux.initial_value','It must be a numeric value');
                                status = 0; return;
                            end
                            pc.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(HF,'slope'))
                            this.missingDataError('PrescribedCondition.heat_flux.slope');
                            status = 0; return;
                        end
                        slope = HF.slope;
                        if (~this.isDoubleArray(slope,1))
                            this.invalidParamError('PrescribedCondition.heat_flux.slope','It must be a numeric value');
                            status = 0; return;
                        end
                        pc.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        pc = Condition_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(HF,'base_value') || ~isfield(HF,'amplitude') || ~isfield(HF,'period'))
                            this.missingDataError('PrescribedCondition.heat_flux.base_value and/or PrescribedCondition.heat_flux.amplitude and/or PrescribedCondition.heat_flux.period');
                            status = 0; return;
                        end
                        val       = HF.base_value;
                        amplitude = HF.amplitude;
                        period    = HF.period;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('PrescribedCondition.heat_flux.base_value','It must be a numeric value');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,1) || amplitude < 0)
                            this.invalidParamError('PrescribedCondition.heat_flux.amplitude','It must be a positive value with the amplitude of oscillation');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            this.invalidParamError('PrescribedCondition.heat_flux.period','It must be a positive value with the period of oscillation');
                            status = 0; return;
                        end
                        pc.base_value = val;
                        pc.amplitude  = amplitude;
                        pc.period     = period;
                        
                        % Shift
                        if (isfield(HF,'shift'))
                            shift = HF.shift;
                            if (~this.isDoubleArray(shift,1))
                                this.invalidParamError('PrescribedCondition.heat_flux.shift','It must be a numeric value with the shift of the oscillation');
                                status = 0; return;
                            end
                            pc.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        pc = Condition_Table();
                        
                        % Table values
                        if (isfield(HF,'values'))
                            vals = HF.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                this.invalidParamError('PrescribedCondition.heat_flux.values','It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values');
                                status = 0; return;
                            end
                        elseif (isfield(HF,'file'))
                            file = HF.file;
                            if (~this.isStringArray(file,1))
                                this.invalidParamError('PrescribedCondition.heat_flux.file','It must be a string with the file name');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(drv.path,file),2);
                            if (status == 0)
                                return;
                            end
                        else
                            this.missingDataError('PrescribedCondition.heat_flux.values or PrescribedCondition.heat_flux.file');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 2)
                            this.invalidParamError('PrescribedCondition.heat_flux.values','It must contain 2 columns (one for the independent variable values and another for the heat flux values), and at least 2 points');
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
                                this.invalidOptError('PrescribedCondition.heat_flux.interpolation','linear, makima, cubic, pchip or spline');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(pc.val_x,1) < 2)
                                    this.invalidParamError('PrescribedCondition.heat_flux.values','It must contain at least 2 points for linear interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(pc.val_x,1) < 2)
                                    this.invalidParamError('PrescribedCondition.heat_flux.values','It must contain at least 2 points for makima interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(pc.val_x,1) < 3)
                                    this.invalidParamError('PrescribedCondition.heat_flux.values','It must contain at least 3 points for cubic interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(pc.val_x,1) < 4)
                                    this.invalidParamError('PrescribedCondition.heat_flux.values','It must contain at least 4 points for pchip interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(pc.val_x,1) < 4)
                                    this.invalidParamError('PrescribedCondition.heat_flux.values','It must contain at least 4 points for spline interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_SPLINE;
                            end
                        end
                    else
                        this.invalidOptError('PrescribedCondition.heat_flux.type','constant, linear, oscillatory, table');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(HF,'interval'))
                        interval = HF.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            this.invalidParamError('PrescribedCondition.heat_flux.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
                            status = 0; return;
                        end
                        pc.interval  = interval;
                        pc.init_time = min(0,min(interval));
                    else
                        pc.init_time = 0;
                    end
                    
                    % Add handle to prescribed condition to selected particles
                    model_parts = string(HF.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('PrescribedCondition.heat_flux.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.pc_heatflux] = deal(pc);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in PrescribedCondition.heat_flux.');
                                continue;
                            end
                            [mp.particles.pc_heatflux] = deal(pc);
                        end
                    end
                end
            end
            
            % HEAT RATE
            if (isfield(PC,'heat_rate'))
                for i = 1:length(PC.heat_rate)
                    HF = PC.heat_rate(i);
                    if (~isfield(HF,'type') || ~isfield(HF,'model_parts'))
                        this.missingDataError('PrescribedCondition.heat_rate.type or PrescribedCondition.heat_rate.model_parts');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(HF.type);
                    if (~this.isStringArray(type,1))
                        this.invalidParamError('PrescribedCondition.heat_rate.type','It must be a pre-defined string of the condition type');
                        status = 0; return;
                        
                    elseif (strcmp(type,'constant'))
                        % Create object
                        pc = Condition_Constant();
                        
                        % Value
                        if (~isfield(HF,'value'))
                            this.missingDataError('PrescribedCondition.heat_rate.value');
                            status = 0; return;
                        end
                        val = HF.value;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('PrescribedCondition.heat_rate.value','It must be a numeric value');
                            status = 0; return;
                        end
                        pc.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        pc = Condition_Linear();
                        
                        % Initial value
                        if (isfield(HF,'initial_value'))
                            val = HF.initial_value;
                            if (~this.isDoubleArray(val,1))
                                this.invalidParamError('PrescribedCondition.heat_rate.initial_value','It must be a numeric value');
                                status = 0; return;
                            end
                            pc.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(HF,'slope'))
                            this.missingDataError('PrescribedCondition.heat_rate.slope');
                            status = 0; return;
                        end
                        slope = HF.slope;
                        if (~this.isDoubleArray(slope,1))
                            this.invalidParamError('PrescribedCondition.heat_rate.slope','It must be a numeric value');
                            status = 0; return;
                        end
                        pc.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        pc = Condition_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(HF,'base_value') || ~isfield(HF,'amplitude') || ~isfield(HF,'period'))
                            this.missingDataError('PrescribedCondition.heat_rate.base_value and/or PrescribedCondition.heat_rate.amplitude and/or PrescribedCondition.heat_rate.period');
                            status = 0; return;
                        end
                        val       = HF.base_value;
                        amplitude = HF.amplitude;
                        period    = HF.period;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('PrescribedCondition.heat_rate.base_value','It must be a numeric value');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,1) || amplitude < 0)
                            this.invalidParamError('PrescribedCondition.heat_rate.amplitude','It must be a positive value with the amplitude of oscillation');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            this.invalidParamError('PrescribedCondition.heat_rate.period','It must be a positive value with the period of oscillation');
                            status = 0; return;
                        end
                        pc.base_value = val;
                        pc.amplitude  = amplitude;
                        pc.period     = period;
                        
                        % Shift
                        if (isfield(HF,'shift'))
                            shift = HF.shift;
                            if (~this.isDoubleArray(shift,1))
                                this.invalidParamError('PrescribedCondition.heat_rate.shift','It must be a numeric value with the shift of the oscillation');
                                status = 0; return;
                            end
                            pc.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        pc = Condition_Table();
                        
                        % Table values
                        if (isfield(HF,'values'))
                            vals = HF.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                this.invalidParamError('PrescribedCondition.heat_rate.values','It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values');
                                status = 0; return;
                            end
                        elseif (isfield(HF,'file'))
                            file = HF.file;
                            if (~this.isStringArray(file,1))
                                this.invalidParamError('PrescribedCondition.heat_rate.file','It must be a string with the file name');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(drv.path,file),2);
                            if (status == 0)
                                return;
                            end
                        else
                            this.missingDataError('PrescribedCondition.heat_rate.values or PrescribedCondition.heat_rate.file');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 2)
                            this.invalidParamError('PrescribedCondition.heat_rate.values','It must contain 2 columns (one for the independent variable values and another for the heat rate values), and at least 2 points');
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
                                this.invalidOptError('PrescribedCondition.heat_rate.interpolation','linear, makima, cubic, pchip or spline');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(pc.val_x,1) < 2)
                                    this.invalidParamError('PrescribedCondition.heat_rate.values','It must contain at least 2 points for linear interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(pc.val_x,1) < 2)
                                    this.invalidParamError('PrescribedCondition.heat_rate.values','It must contain at least 2 points for makima interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(pc.val_x,1) < 3)
                                    this.invalidParamError('PrescribedCondition.heat_rate.values','It must contain at least 3 points for cubic interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(pc.val_x,1) < 4)
                                    this.invalidParamError('PrescribedCondition.heat_rate.values','It must contain at least 4 points for pchip interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(pc.val_x,1) < 4)
                                    this.invalidParamError('PrescribedCondition.heat_rate.values','It must contain at least 4 points for spline interpolation');
                                    status = 0; return;
                                end
                                pc.interp = pc.INTERP_SPLINE;
                            end
                        end
                    else
                        this.invalidOptError('PrescribedCondition.heat_rate.type','constant, linear, oscillatory, table');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(HF,'interval'))
                        interval = HF.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            this.invalidParamError('PrescribedCondition.heat_rate.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
                            status = 0; return;
                        end
                        pc.interval  = interval;
                        pc.init_time = min(0,min(interval));
                    else
                        pc.init_time = 0;
                    end
                    
                    % Add handle to prescribed condition to selected particles
                    model_parts = string(HF.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('PrescribedCondition.heat_rate.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.pc_heatrate] = deal(pc);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in PrescribedCondition.heat_rate.');
                                continue;
                            end
                            [mp.particles.pc_heatrate] = deal(pc);
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getFixedCondition(this,json,drv)
            status = 1;
            if (~isfield(json,'FixedCondition'))
                return;
            end
            FC = json.FixedCondition;
            
            fields = fieldnames(FC);
            for i = 1:length(fields)
                f = string(fields(i));
                if (~strcmp(f,'velocity_translation') && ...
                    ~strcmp(f,'velocity_rotation')    &&...
                    ~strcmp(f,'temperature'))
                    this.warnMsg('A nonexistent field was identified in FixedCondition. It will be ignored.');
                end
            end
            
            % VELOCITY TRANSLATION
            if (isfield(FC,'velocity_translation'))
                for i = 1:length(FC.velocity_translation)
                    V = FC.velocity_translation(i);
                    if (~isfield(V,'type') || ~isfield(V,'model_parts'))
                        this.missingDataError('FixedCondition.velocity_translation.type and/or FixedCondition.velocity_translation.model_parts');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(V.type);
                    if (~this.isStringArray(type,1))
                        this.invalidParamError('FixedCondition.velocity_translation.type','It must be a pre-defined string of the condition type');
                        status = 0; return;
                        
                    elseif (strcmp(type,'constant'))
                        % Create object
                        cond = Condition_Constant();
                        
                        % Value
                        if (~isfield(V,'value'))
                            this.missingDataError('FixedCondition.velocity_translation.value');
                            status = 0; return;
                        end
                        val = V.value;
                        if (~this.isDoubleArray(val,2))
                            this.invalidParamError('FixedCondition.velocity_translation.value','It must be a pair of numeric values');
                            status = 0; return;
                        end
                        cond.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        cond = Condition_Linear();
                        
                        % Initial value
                        if (isfield(V,'initial_value'))
                            val = V.initial_value;
                            if (~this.isDoubleArray(val,2))
                                this.invalidParamError('FixedCondition.velocity_translation.initial_value','It must be a pair of numeric values');
                                status = 0; return;
                            end
                            cond.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(V,'slope'))
                            this.missingDataError('FixedCondition.velocity_translation.slope');
                            status = 0; return;
                        end
                        slope = V.slope;
                        if (~this.isDoubleArray(slope,2))
                            this.invalidParamError('FixedCondition.velocity_translation.slope','It must be a pair of numeric values');
                            status = 0; return;
                        end
                        cond.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        cond = Condition_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(V,'base_value') || ~isfield(V,'amplitude') || ~isfield(V,'period'))
                            this.missingDataError('FixedCondition.velocity_translation.base_value and/or FixedCondition.velocity_translation.amplitude and/or FixedCondition.velocity_translation.period');
                            status = 0; return;
                        end
                        val       = V.base_value;
                        amplitude = V.amplitude;
                        period    = V.period;
                        if (~this.isDoubleArray(val,2))
                            this.invalidParamError('FixedCondition.velocity_translation.base_value','It must be a pair of numeric values with X,Y velocity components');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,2) || any(amplitude < 0))
                            this.invalidParamError('FixedCondition.velocity_translation.amplitude','It must be a pair of positive values with X,Y velocity components');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            this.invalidParamError('FixedCondition.velocity_translation.period','It must be a positive value with the period of oscillation');
                            status = 0; return;
                        end
                        cond.base_value = val;
                        cond.amplitude  = amplitude;
                        cond.period     = period;
                        
                        % Shift
                        if (isfield(V,'shift'))
                            shift = V.shift;
                            if (~this.isDoubleArray(shift,1))
                                this.invalidParamError('FixedCondition.velocity_translation.shift','It must be a numeric value with the shift of the oscillation');
                                status = 0; return;
                            end
                            cond.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        cond = Condition_Table();
                        
                        % Table values
                        if (isfield(V,'values'))
                            vals = V.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                this.invalidParamError('FixedCondition.velocity_translation.values','It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values');
                                status = 0; return;
                            end
                        elseif (isfield(V,'file'))
                            file = V.file;
                            if (~this.isStringArray(file,1))
                                this.invalidParamError('FixedCondition.velocity_translation.file','It must be a string with the file name');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(drv.path,file),3);
                            if (status == 0)
                                return;
                            end
                        else
                            this.missingDataError('FixedCondition.velocity_translation.values or FixedCondition.velocity_translation.file');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 3)
                            this.invalidParamError('FixedCondition.velocity_translation.values','It must contain 3 columns (one for the independent variable values and 2 for the velocity X,Y component values), and at least 2 points');
                            status = 0; return;
                        end
                        cond.val_x = vals(:,1);
                        cond.val_y = vals(:,2:3);
                        
                        % Interpolation method
                        if (isfield(V,'interpolation'))
                            interp = V.interpolation;
                            if (~this.isStringArray(interp,1) ||...
                               (~strcmp(interp,'linear') &&...
                                ~strcmp(interp,'makima') &&...
                                ~strcmp(interp,'cubic')  &&...
                                ~strcmp(interp,'pchip')  &&...
                                ~strcmp(interp,'spline')))
                                this.invalidOptError('FixedCondition.velocity_translation.interpolation','linear, makima, cubic, pchip or spline');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(cond.val_x,1) < 2)
                                    this.invalidParamError('FixedCondition.velocity_translation.values','It must contain at least 2 points for linear interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(cond.val_x,1) < 2)
                                    this.invalidParamError('FixedCondition.velocity_translation.values','It must contain at least 2 points for makima interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(cond.val_x,1) < 3)
                                    this.invalidParamError('FixedCondition.velocity_translation.values','It must contain at least 3 points for cubic interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(cond.val_x,1) < 4)
                                    this.invalidParamError('FixedCondition.velocity_translation.values','It must contain at least 4 points for pchip interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(cond.val_x,1) < 4)
                                    this.invalidParamError('FixedCondition.velocity_translation.values','It must contain at least 4 points for spline interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_SPLINE;
                            end
                        end
                    else
                        this.invalidOptError('FixedCondition.velocity_translation.type','constant, linear, oscillatory, table');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(V,'interval'))
                        interval = V.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            this.invalidParamError('FixedCondition.velocity_translation.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
                            status = 0; return;
                        end
                        cond.interval  = interval;
                        cond.init_time = min(0,min(interval));
                    else
                        cond.init_time = 0;
                    end
                    
                    % Add handle to fixed condition to selected elements
                    model_parts = string(V.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('FixedCondition.velocity_translation.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.fc_translation] = deal(cond);
                        elseif (strcmp(name,'WALLS'))
                            [drv.walls.fc_translation] = deal(cond);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in FixedCondition.velocity_translation.');
                                continue;
                            end
                            [mp.particles.fc_translation] = deal(cond);
                            [mp.walls.fc_translation]     = deal(cond);
                        end
                    end
                end
            end
            
            % VELOCITY ROTATION
            if (isfield(FC,'velocity_rotation'))
                for i = 1:length(FC.velocity_rotation)
                    V = FC.velocity_rotation(i);
                    if (~isfield(V,'type') || ~isfield(V,'model_parts'))
                        this.missingDataError('FixedCondition.velocity_rotation.type and/or FixedCondition.velocity_rotation.model_parts');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(V.type);
                    if (~this.isStringArray(type,1))
                        this.invalidParamError('FixedCondition.velocity_rotation.type','It must be a pre-defined string of the condition type');
                        status = 0; return;
                        
                    elseif (strcmp(type,'constant'))
                        % Create object
                        cond = Condition_Constant();
                        
                        % Value
                        if (~isfield(V,'value'))
                            this.missingDataError('FixedCondition.velocity_rotation.value');
                            status = 0; return;
                        end
                        val = V.value;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('FixedCondition.velocity_rotation.value','It must be a numeric value');
                            status = 0; return;
                        end
                        cond.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        cond = Condition_Linear();
                        
                        % Initial value
                        if (isfield(V,'initial_value'))
                            val = V.initial_value;
                            if (~this.isDoubleArray(val,1))
                                this.invalidParamError('FixedCondition.velocity_rotation.initial_value','It must be a numeric value');
                                status = 0; return;
                            end
                            cond.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(V,'slope'))
                            this.missingDataError('FixedCondition.velocity_rotation.slope');
                            status = 0; return;
                        end
                        slope = V.slope;
                        if (~this.isDoubleArray(slope,1))
                            this.invalidParamError('FixedCondition.velocity_rotation.slope','It must be a numeric value');
                            status = 0; return;
                        end
                        cond.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        cond = Condition_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(V,'base_value') || ~isfield(V,'amplitude') || ~isfield(V,'period'))
                            this.missingDataError('FixedCondition.velocity_rotation.base_value and/or FixedCondition.velocity_rotation.amplitude and/or FixedCondition.velocity_rotation.period');
                            status = 0; return;
                        end
                        val       = V.base_value;
                        amplitude = V.amplitude;
                        period    = V.period;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('FixedCondition.velocity_rotation.base_value','It must be a numeric value');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,1) || amplitude < 0)
                            this.invalidParamError('FixedCondition.velocity_rotation.amplitude','It must be a positive value');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            this.invalidParamError('FixedCondition.velocity_rotation.period','It must be a positive value with the period of oscillation');
                            status = 0; return;
                        end
                        cond.base_value = val;
                        cond.amplitude  = amplitude;
                        cond.period     = period;
                        
                        % Shift
                        if (isfield(V,'shift'))
                            shift = V.shift;
                            if (~this.isDoubleArray(shift,1))
                                this.invalidParamError('FixedCondition.velocity_rotation.shift','It must be a numeric value with the shift of the oscillation');
                                status = 0; return;
                            end
                            cond.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        cond = Condition_Table();
                        
                        % Table values
                        if (isfield(V,'values'))
                            vals = V.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                this.invalidParamError('FixedCondition.velocity_rotation.values','It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values');
                                status = 0; return;
                            end
                        elseif (isfield(V,'file'))
                            file = V.file;
                            if (~this.isStringArray(file,1))
                                this.invalidParamError('FixedCondition.velocity_rotation.file','It must be a string with the file name');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(drv.path,file),2);
                            if (status == 0)
                                return;
                            end
                        else
                            this.missingDataError('FixedCondition.velocity_rotation.values or FixedCondition.velocity_rotation.file');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 2)
                            this.invalidParamError('FixedCondition.velocity_rotation.values','It must contain 2 columns (one for the independent variable values and another for the velocity values), and at least 2 points');
                            status = 0; return;
                        end
                        cond.val_x = vals(:,1);
                        cond.val_y = vals(:,2);
                        
                        % Interpolation method
                        if (isfield(V,'interpolation'))
                            interp = V.interpolation;
                            if (~this.isStringArray(interp,1) ||...
                               (~strcmp(interp,'linear') &&...
                                ~strcmp(interp,'makima') &&...
                                ~strcmp(interp,'cubic')  &&...
                                ~strcmp(interp,'pchip')  &&...
                                ~strcmp(interp,'spline')))
                                this.invalidOptError('FixedCondition.velocity_rotation.interpolation','linear, makima, cubic, pchip or spline');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(cond.val_x,1) < 2)
                                    this.invalidParamError('FixedCondition.velocity_rotation.values','It must contain at least 2 points for linear interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(cond.val_x,1) < 2)
                                    this.invalidParamError('FixedCondition.velocity_rotation.values','It must contain at least 2 points for makima interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(cond.val_x,1) < 3)
                                    this.invalidParamError('FixedCondition.velocity_rotation.values','It must contain at least 3 points for cubic interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(cond.val_x,1) < 4)
                                    this.invalidParamError('FixedCondition.velocity_rotation.values','It must contain at least 4 points for pchip interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(cond.val_x,1) < 4)
                                    this.invalidParamError('FixedCondition.velocity_rotation.values','It must contain at least 4 points for spline interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_SPLINE;
                            end
                        end
                    else
                        this.invalidOptError('FixedCondition.velocity_rotation.type','constant, linear, oscillatory, table');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(V,'interval'))
                        interval = V.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            this.invalidParamError('FixedCondition.velocity_rotation.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
                            status = 0; return;
                        end
                        cond.interval  = interval;
                        cond.init_time = min(0,min(interval));
                    else
                        cond.init_time = 0;
                    end
                    
                    % Add handle to fixed condition to selected elements
                    model_parts = string(V.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('FixedCondition.velocity_rotation.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.fc_rotation] = deal(cond);
                        elseif (strcmp(name,'WALLS'))
                            [drv.walls.fc_rotation] = deal(cond);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in FixedCondition.velocity_rotation.');
                                continue;
                            end
                            [mp.particles.fc_rotation] = deal(cond);
                            [mp.walls.fc_rotation]     = deal(cond);
                        end
                    end
                end
            end
            
            % TEMPERATURE
            if (isfield(FC,'temperature'))
                for i = 1:length(FC.temperature)
                    T = FC.temperature(i);
                    if (~isfield(T,'type') || ~isfield(T,'model_parts'))
                        this.missingDataError('FixedCondition.temperature.type and/or FixedCondition.temperature.model_parts');
                        status = 0; return;
                    end
                    
                    % Type
                    type = string(T.type);
                    if (~this.isStringArray(type,1))
                        this.invalidParamError('FixedCondition.temperature.type','It must be a pre-defined string of the condition type');
                        status = 0; return;
                        
                    elseif (strcmp(type,'constant'))
                        % Create object
                        cond = Condition_Constant();
                        
                        % Value
                        if (~isfield(T,'value'))
                            this.missingDataError('FixedCondition.temperature.value');
                            status = 0; return;
                        end
                        val = T.value;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('FixedCondition.temperature.value','It must be a numeric value');
                            status = 0; return;
                        end
                        cond.value = val;
                        
                    elseif (strcmp(type,'linear'))
                        % Create object
                        cond = Condition_Linear();
                        
                        % Initial value
                        if (isfield(T,'initial_value'))
                            val = T.initial_value;
                            if (~this.isDoubleArray(val,1))
                                this.invalidParamError('FixedCondition.temperature.initial_value','It must be a numeric value');
                                status = 0; return;
                            end
                            cond.init_value = val;
                        end
                        
                        % Slope
                        if (~isfield(T,'slope'))
                            this.missingDataError('FixedCondition.temperature.slope');
                            status = 0; return;
                        end
                        slope = T.slope;
                        if (~this.isDoubleArray(slope,1))
                            this.invalidParamError('FixedCondition.temperature.slope','It must be a numeric value');
                            status = 0; return;
                        end
                        cond.slope = slope;
                        
                    elseif (strcmp(type,'oscillatory'))
                        % Create object
                        cond = Condition_Oscillatory();
                        
                        % Base value, amplitude and period
                        if (~isfield(T,'base_value') || ~isfield(T,'amplitude') || ~isfield(T,'period'))
                            this.missingDataError('FixedCondition.temperature.base_value and/or FixedCondition.temperature.amplitude and/or FixedCondition.temperature.period');
                            status = 0; return;
                        end
                        val       = T.base_value;
                        amplitude = T.amplitude;
                        period    = T.period;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('FixedCondition.temperature.base_value','It must be a numeric value');
                            status = 0; return;
                        elseif (~this.isDoubleArray(amplitude,1) || amplitude < 0)
                            this.invalidParamError('FixedCondition.temperature.amplitude','It must be a positive value with the amplitude of oscillation');
                            status = 0; return;
                        elseif (~this.isDoubleArray(period,1) || period <= 0)
                            this.invalidParamError('FixedCondition.temperature.period','It must be a positive value with the period of oscillation');
                            status = 0; return;
                        end
                        cond.base_value = val;
                        cond.amplitude  = amplitude;
                        cond.period     = period;
                        
                        % Shift
                        if (isfield(T,'shift'))
                            shift = T.shift;
                            if (~this.isDoubleArray(shift,1))
                                this.invalidParamError('FixedCondition.temperature.shift','It must be a numeric value with the shift of the oscillation');
                                status = 0; return;
                            end
                            cond.shift = shift;
                        end
                        
                    elseif (strcmp(type,'table'))
                        % Create object
                        cond = Condition_Table();
                        
                        % Table values
                        if (isfield(T,'values'))
                            vals = T.values';
                            if (~this.isDoubleArray(vals,length(vals)))
                                this.invalidParamError('FixedCondition.temperature.values','It must be a numeric table with the first row as the independent variable values and the second as the dependent variable values');
                                status = 0; return;
                            end
                        elseif (isfield(T,'file'))
                            file = T.file;
                            if (~this.isStringArray(file,1))
                                this.invalidParamError('FixedCondition.temperature.file','It must be a string with the file name');
                                status = 0; return;
                            end
                            [status,vals] = this.readTable(fullfile(drv.path,file),2);
                            if (status == 0)
                                return;
                            end
                        else
                            this.missingDataError('FixedCondition.temperature.values or FixedCondition.temperature.file');
                            status = 0; return;
                        end
                        if (size(vals,1) < 2 || size(vals,2) ~= 2)
                            this.invalidParamError('FixedCondition.temperature.values','It must contain 2 columns (one for the independent variable values and another for the temperature values), and at least 2 points');
                            status = 0; return;
                        end
                        cond.val_x = vals(:,1);
                        cond.val_y = vals(:,2);
                        
                        % Interpolation method
                        if (isfield(T,'interpolation'))
                            interp = T.interpolation;
                            if (~this.isStringArray(interp,1) ||...
                               (~strcmp(interp,'linear') &&...
                                ~strcmp(interp,'makima') &&...
                                ~strcmp(interp,'cubic')  &&...
                                ~strcmp(interp,'pchip')  &&...
                                ~strcmp(interp,'spline')))
                                this.invalidOptError('FixedCondition.temperature.interpolation','linear, makima, cubic, pchip or spline');
                                status = 0; return;
                            elseif (strcmp(interp,'linear'))
                                if (size(cond.val_x,1) < 2)
                                    this.invalidParamError('FixedCondition.temperature.values','It must contain at least 2 points for linear interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_LINEAR;
                            elseif (strcmp(interp,'makima'))
                                if (size(cond.val_x,1) < 2)
                                    this.invalidParamError('FixedCondition.temperature.values','It must contain at least 2 points for makima interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_MAKIMA;
                            elseif (strcmp(interp,'cubic'))
                                if (size(cond.val_x,1) < 3)
                                    this.invalidParamError('FixedCondition.temperature.values','It must contain at least 3 points for cubic interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_CUBIC;
                            elseif (strcmp(interp,'pchip'))
                                if (size(cond.val_x,1) < 4)
                                    this.invalidParamError('FixedCondition.temperature.values','It must contain at least 4 points for pchip interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_PCHIP;
                            elseif (strcmp(interp,'spline'))
                                if (size(cond.val_x,1) < 4)
                                    this.invalidParamError('FixedCondition.temperature.values','It must contain at least 4 points for spline interpolation');
                                    status = 0; return;
                                end
                                cond.interp = cond.INTERP_SPLINE;
                            end
                        end
                    else
                        this.invalidOptError('FixedCondition.temperature.type','constant, linear, oscillatory, table');
                        status = 0; return;
                    end
                    
                    % Interval
                    if (isfield(T,'interval'))
                        interval = T.interval;
                        if (~this.isDoubleArray(interval,2) || interval(1) >= interval(2))
                            this.invalidParamError('FixedCondition.temperature.interval','It must be a pair of numeric values and the minimum value must be smaller than the maximum');
                            status = 0; return;
                        end
                        cond.interval  = interval;
                        cond.init_time = min(0,min(interval));
                    else
                        cond.init_time = 0;
                    end
                    
                    % Add handle to fixed condition to selected elements
                    model_parts = string(T.model_parts);
                    for j = 1:length(model_parts)
                        name = model_parts(j);
                        if (~this.isStringArray(name,1))
                            this.invalidParamError('FixedCondition.temperature.model_parts','It must be a list of strings containing the names of the model parts');
                            status = 0; return;
                        elseif (strcmp(name,'PARTICLES'))
                            [drv.particles.fc_temperature] = deal(cond);
                        elseif (strcmp(name,'WALLS'))
                            [drv.walls.fc_temperature] = deal(cond);
                        else
                            mp = findobj(drv.mparts,'name',name);
                            if (isempty(mp))
                                this.warnMsg('Nonexistent model part used in FixedCondition.temperature.');
                                continue;
                            end
                            [mp.particles.fc_temperature] = deal(cond);
                            [mp.walls.fc_temperature]     = deal(cond);
                        end
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getMaterial(this,json,drv)
            status = 1;
            if (~isfield(json,'Material'))
                this.missingDataError('Material parameters');
                status = 0; return;
            end
            
            for i = 1:length(json.Material)
                M = json.Material(i);
                if (~isfield(M,'name') || ~isfield(M,'model_parts') || ~isfield(M,'properties'))
                    this.missingDataError('Material.name and/or Material.model_parts and/or Material.properties');
                    status = 0; return;
                end
                
                % Create material object
                mat = Material();
                drv.n_materials = drv.n_materials + 1;
                drv.materials(drv.n_materials) = mat;
                
                % Name
                name = string(M.name);
                if (~this.isStringArray(name,1))
                    this.invalidParamError('Material.name','It must be a string with the name representing the material');
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
                    mat.young0 = prop.young_modulus_real;
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
                    mat.hcapacity = prop.heat_capacity;
                end
                
                if (msg < 0)
                    this.invalidParamError('Material.properties','Properties must be numerical values');
                    status = 0; return;
                elseif(msg > 0)
                    this.warnMsg('Unphysical value found for material property.');
                end
                
                % Apply material to selected elements
                model_parts = string(M.model_parts);
                for j = 1:length(model_parts)
                    mp_name = model_parts(j);
                    if (~this.isStringArray(mp_name,1))
                        this.invalidParamError('Material.model_parts','It must be a list of strings containing the names of the model parts');
                        status = 0; return;
                    elseif (strcmp(mp_name,'PARTICLES'))
                        [drv.particles.material] = deal(mat);
                    elseif (strcmp(mp_name,'WALLS'))
                        [drv.walls.material] = deal(mat);
                    else
                        mp = findobj(drv.mparts,'name',name);
                        if (isempty(mp))
                            this.warnMsg('Nonexistent model part used in Material.');
                            continue;
                        end
                        [mp.particles.material] = deal(mat);
                        [mp.walls.material]     = deal(mat);
                    end
                end
            end
            
            % Checks
            if (drv.n_materials == 0)
                this.invalidParamError('No valid material was found.',[]);
                status = 0; return;
            else
                for i = 1:drv.n_materials
                    if (length(findobj(drv.materials,'name',drv.materials(i).name)) > 1)
                        this.invalidParamError('Repeated material name.','Material names must be unique');
                        status = 0; return;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getInteractionModel(this,json,drv)
            status = 1;
            if (~isfield(json,'InteractionModel') || isempty(json.InteractionModel))
                if (drv.n_particles > 1 || drv.n_walls > 0)
                    this.warnMsg('No interaction model was provided.');
                end
                drv.search.b_interact = Interact();
                return;
            end
            
            % Single case: Only 1 interaction model provided
            % (applied to the interaction between all elements)
            if (length(json.InteractionModel) == 1)
                % Create base object for common interactions
                drv.search.b_interact = Interact();
                
                % Interaction models
                if (~this.interactContactForceNormal(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
                if (~this.interactContactForceTangent(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
                if (~this.interactRollResist(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
                if (~this.interactAreaCorrection(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
                if (~this.interactConductionDirect(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
                if (~this.interactConductionIndirect(json.InteractionModel,drv))
                    status = 0;
                    return;
                end
            end
            
            % Multiple case:
            if (length(json.InteractionModel) > 1)
                fprintf(2,'Multiple interaction models is not yet available.\n');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = getInteractionAssignment(this,json,drv)
            status = 1;
            if (~isempty(drv.search.b_interact))
                if (isfield(json,'InteractionAssignment'))
                    this.warnMsg('Only one InteractionModel was created and will be applied to all interactions, so InteractionAssignment will be ignored.');
                end
                return;
            elseif (~isfield(json,'InteractionAssignment'))
                this.missingDataError('InteractionModel parameters');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = getOutput(this,json,drv)
            status = 1;
            if (~isfield(json,'Output'))
                return;
            end
            OUT = json.Output;
            
            % Progress print frequency
            if (isfield(OUT,'progress_print'))
                prog = OUT.progress_print;
                if (~this.isDoubleArray(prog,1) || prog <= 0 || prog > 100)
                    this.invalidParamError('Output.progress_print','It must be a numeric value between 0.0 and 100.0');
                    status = 0; return;
                end
                drv.nprog = prog;
            end
            
            % Number of outputs
            if (isfield(OUT,'number_output'))
                nout = OUT.number_output;
                if (~this.isIntArray(nout,1) || nout <= 0)
                    this.invalidParamError('Output.number_output','It must be a positive integer');
                    status = 0; return;
                end
                drv.nout = nout;
            end
            
            % Save workspace
            if (isfield(OUT,'save_workspace'))
                save_ws = OUT.save_workspace;
                if (~this.isLogicalArray(save_ws,1))
                    this.invalidParamError('Output.save_workspace','It must be a boolean: true or false');
                    status = 0; return;
                end
                drv.save_ws = save_ws;
            end
            
            % Reults to store (besides those always saved and needed for graphs/animations)
            if (isfield(OUT,'saved_results'))
                % Possible results
                results_general = ["time","step","radius","mass","coord_x","coord_y","orientation","wall_position"];
                results_mech    = ["force_x","force_y","torque",...
                                   "velocity_x","velocity_y","velocity_rot",...
                                   "acceleration_x","acceleration_y","acceleration_rot"];
                results_therm   = ["heat_rate","temperature","wall_temperature"];
                
                for i = 1:length(OUT.saved_results)
                    % Check data
                    res = string(OUT.saved_results(i));
                    if (~this.isStringArray(res,1))
                        this.invalidParamError('Output.saved_results','It must be a list of pre-defined strings of the result types');
                        status = 0; return;
                    elseif (~ismember(res,results_general) &&...
                            ~ismember(res,results_mech)    &&...
                            ~ismember(res,results_therm))
                        this.warnMsg('Result %s is not available is this type of analysis.',res);
                        continue;
                    elseif (drv.type == drv.MECHANICAL     &&...
                            ~ismember(res,results_general) &&...
                            ~ismember(res,results_mech))
                        this.warnMsg('Result %s is not available is this type of analysis.',res);
                        continue;
                    elseif (drv.type == drv.THERMAL        &&...
                            ~ismember(res,results_general) &&...
                            ~ismember(res,results_therm))
                        this.warnMsg('Result %s is not available is this type of analysis.',res);
                        continue;
                    end
                    
                    % Set flag
                    if (strcmp(res,'time'))
                        drv.result.has_time = true;
                    elseif (strcmp(res,'step'))
                        drv.result.has_step = true;
                    elseif (strcmp(res,'radius'))
                        drv.result.has_radius = true;
                    elseif (strcmp(res,'mass'))
                        drv.result.has_mass = true;
                    elseif (strcmp(res,'coord_x'))
                        drv.result.has_coord_x = true;
                    elseif (strcmp(res,'coord_y'))
                        drv.result.has_coord_y = true;
                    elseif (strcmp(res,'orientation'))
                        drv.result.has_orientation = true;
                    elseif (strcmp(res,'wall_position'))
                        drv.result.has_wall_position = true;
                    elseif (strcmp(res,'force_x'))
                        drv.result.has_force_x = true;
                    elseif (strcmp(res,'force_y'))
                        drv.result.has_force_y = true;
                    elseif (strcmp(res,'torque'))
                        drv.result.has_torque = true;
                    elseif (strcmp(res,'velocity_x'))
                        drv.result.has_velocity_x = true;
                    elseif (strcmp(res,'velocity_y'))
                        drv.result.has_velocity_y = true;
                    elseif (strcmp(res,'velocity_rot'))
                        drv.result.has_velocity_rot = true;
                    elseif (strcmp(res,'acceleration_x'))
                        drv.result.has_acceleration_x = true;
                    elseif (strcmp(res,'acceleration_y'))
                        drv.result.has_acceleration_y = true;
                    elseif (strcmp(res,'acceleration_rot'))
                        drv.result.has_acceleration_rot = true;
                    elseif (strcmp(res,'heat_rate'))
                        drv.result.has_heat_rate = true;
                    elseif (strcmp(res,'temperature'))
                        drv.result.has_temperature = true;
                    elseif (strcmp(res,'wall_temperature'))
                        drv.result.has_wall_temperature = true;
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getGraph(this,json,drv)
            status = 1;
            if (~isfield(json,'Graph'))
                return;
            end
            
            for i = 1:length(json.Graph)
                GRA = json.Graph(i);
                
                % Create graph object
                gra = Graph();
                drv.graphs(i) = gra;
                
                % Title
                if (isfield(GRA,'title'))
                    title = string(GRA.title);
                    if (~this.isStringArray(title,1))
                        this.invalidParamError('Graph.title','It must be a string with the title of the graph');
                        status = 0; return;
                    end
                    gra.gtitle = title;
                else
                    gra.gtitle = sprintf('Graph %d',i);
                end
                
                % Array of possible results
                global_results = ["time","step"];
                results_mech   = ["radius","mass",...
                                  "coordinate_x","coordinate_y","orientation",...
                                  "force_vector","force_modulus","force_x","force_y","torque",...
                                  "velocity_vector","velocity_modulus","velocity_x","velocity_y","velocity_rot",...
                                  "acceleration_vector","acceleration_modulus","acceleration_x","acceleration_y","acceleration_rot"];
                results_therm  = ["heat_rate","temperature"];
                
                % Check and get axes data
                if (~isfield(GRA,'axis_x'))
                    this.missingDataError('Graph.axis_x');
                    status = 0; return;
                elseif (~isfield(GRA,'axis_y'))
                    this.missingDataError('Graph.axis_y');
                    status = 0; return;
                end
                X = string(GRA.axis_x);
                Y = string(GRA.axis_y);
                if (~this.isStringArray(X,1)    ||...
                   (~ismember(X,global_results) &&...
                    ~ismember(X,results_mech)   &&...
                    ~ismember(X,results_therm)))
                    this.invalidParamError('Graph.axis_x','Available result options can be checked in the documentation');
                    status = 0; return;
                elseif (~this.isStringArray(Y,1)    ||...
                       (~ismember(Y,global_results) &&...
                        ~ismember(Y,results_mech)   &&...
                        ~ismember(Y,results_therm)))
                    this.invalidParamError('Graph.axis_y','Available result options can be checked in the documentation');
                    status = 0; return;
                end
                
                % Set X axis data
                if (strcmp(X,'time'))
                    gra.res_x = drv.result.TIME;
                    drv.result.has_time = true;
                elseif (strcmp(X,'step'))
                    gra.res_x = drv.result.STEP;
                    drv.result.has_step = true;
                elseif (strcmp(X,'radius'))
                    gra.res_x = drv.result.RADIUS;
                    drv.result.has_radius = true;
                elseif (strcmp(X,'mass'))
                    gra.res_x = drv.result.MASS;
                    drv.result.has_mass = true;
                elseif (strcmp(X,'coordinate_x'))
                    gra.res_x = drv.result.COORDINATE_X;
                    drv.result.has_coord_x = true;
                elseif (strcmp(X,'coordinate_y'))
                    gra.res_x = drv.result.COORDINATE_Y;
                    drv.result.has_coord_y = true;
                elseif (strcmp(X,'orientation'))
                    gra.res_x = drv.result.ORIENTATION;
                    drv.result.has_orientation = true;
                elseif (strcmp(X,'force_modulus'))
                    gra.res_x = drv.result.FORCE_MOD;
                    drv.result.has_force_x = true;
                    drv.result.has_force_y = true;
                elseif (strcmp(X,'force_x'))
                    gra.res_x = drv.result.FORCE_X;
                    drv.result.has_force_x = true;
                elseif (strcmp(X,'force_y'))
                    gra.res_x = drv.result.FORCE_Y;
                    drv.result.has_force_y = true;
                elseif (strcmp(X,'torque'))
                    gra.res_x = drv.result.TORQUE;
                    drv.result.has_torque = true;
                elseif (strcmp(X,'velocity_modulus'))
                    gra.res_x = drv.result.VELOCITY_MOD;
                    drv.result.has_velocity_x = true;
                    drv.result.has_velocity_y = true;
                elseif (strcmp(X,'velocity_x'))
                    gra.res_x = drv.result.VELOCITY_X;
                    drv.result.has_velocity_x = true;
                elseif (strcmp(X,'velocity_y'))
                    gra.res_x = drv.result.VELOCITY_Y;
                    drv.result.has_velocity_y = true;
                elseif (strcmp(X,'velocity_rot'))
                    gra.res_x = drv.result.VELOCITY_ROT;
                    drv.result.has_velocity_rot = true;
                elseif (strcmp(X,'acceleration_modulus'))
                    gra.res_x = drv.result.ACCELERATION_MOD;
                    drv.result.has_acceleration_x = true;
                    drv.result.has_acceleration_y = true;
                elseif (strcmp(X,'acceleration_x'))
                    gra.res_x = drv.result.ACCELERATION_X;
                    drv.result.has_acceleration_x = true;
                elseif (strcmp(X,'acceleration_y'))
                    gra.res_x = drv.result.ACCELERATION_Y;
                    drv.result.has_acceleration_y = true;
                elseif (strcmp(X,'acceleration_rot'))
                    gra.res_x = drv.result.ACCELERATION_ROT;
                    drv.result.has_acceleration_rot = true;
                elseif (strcmp(X,'temperature'))
                    gra.res_x = drv.result.TEMPERATURE;
                    drv.result.has_temperature = true;
                elseif (strcmp(X,'heat_rate'))
                    gra.res_x = drv.result.HEAT_RATE;
                    drv.result.has_heat_rate = true;
                end
                
                % Set Y axis data
                if (strcmp(Y,'time'))
                    gra.res_y = drv.result.TIME;
                    drv.result.has_time = true;
                elseif (strcmp(Y,'step'))
                    gra.res_y = drv.result.STEP;
                    drv.result.has_step = true;
                elseif (strcmp(Y,'radius'))
                    gra.res_y = drv.result.RADIUS;
                    drv.result.has_radius = true;
                elseif (strcmp(Y,'mass'))
                    gra.res_y = drv.result.MASS;
                    drv.result.has_mass = true;
                elseif (strcmp(Y,'coordinate_x'))
                    gra.res_y = drv.result.COORDINATE_X;
                    drv.result.has_coord_x = true;
                elseif (strcmp(Y,'coordinate_y'))
                    gra.res_y = drv.result.COORDINATE_Y;
                    drv.result.has_coord_y = true;
                elseif (strcmp(Y,'orientation'))
                    gra.res_y = drv.result.ORIENTATION;
                    drv.result.has_orientation = true;
                elseif (strcmp(Y,'force_modulus'))
                    gra.res_y = drv.result.FORCE_MOD;
                    drv.result.has_force_x = true;
                    drv.result.has_force_y = true;
                elseif (strcmp(Y,'force_x'))
                    gra.res_y = drv.result.FORCE_X;
                    drv.result.has_force_x = true;
                elseif (strcmp(Y,'force_y'))
                    gra.res_y = drv.result.FORCE_Y;
                    drv.result.has_force_y = true;
                elseif (strcmp(Y,'torque'))
                    gra.res_y = drv.result.TORQUE;
                    drv.result.has_torque = true;
                elseif (strcmp(Y,'velocity_modulus'))
                    gra.res_y = drv.result.VELOCITY_MOD;
                    drv.result.has_velocity_x = true;
                    drv.result.has_velocity_y = true;
                elseif (strcmp(Y,'velocity_x'))
                    gra.res_y = drv.result.VELOCITY_X;
                    drv.result.has_velocity_x = true;
                elseif (strcmp(Y,'velocity_y'))
                    gra.res_y = drv.result.VELOCITY_Y;
                    drv.result.has_velocity_y = true;
                elseif (strcmp(Y,'velocity_rot'))
                    gra.res_y = drv.result.VELOCITY_ROT;
                    drv.result.has_velocity_rot = true;
                elseif (strcmp(Y,'acceleration_modulus'))
                    gra.res_y = drv.result.ACCELERATION_MOD;
                    drv.result.has_acceleration_x = true;
                    drv.result.has_acceleration_y = true;
                elseif (strcmp(Y,'acceleration_x'))
                    gra.res_y = drv.result.ACCELERATION_X;
                    drv.result.has_acceleration_x = true;
                elseif (strcmp(Y,'acceleration_y'))
                    gra.res_y = drv.result.ACCELERATION_Y;
                    drv.result.has_acceleration_y = true;
                elseif (strcmp(Y,'acceleration_rot'))
                    gra.res_y = drv.result.ACCELERATION_ROT;
                    drv.result.has_acceleration_rot = true;
                elseif (strcmp(Y,'temperature'))
                    gra.res_y = drv.result.TEMPERATURE;
                    drv.result.has_temperature = true;
                elseif (strcmp(Y,'heat_rate'))
                    gra.res_y = drv.result.HEAT_RATE;
                    drv.result.has_heat_rate = true;
                end
                
                % Curves
                if (isfield(GRA,'curve'))
                    % Initialize arrays of curve properties
                    nc           = length(GRA.curve);
                    gra.n_curves = nc;
                    gra.names    = strings(nc,1);
                    gra.px       = zeros(nc,1);
                    gra.py       = zeros(nc,1);
                    
                    for j = 1:nc
                        CUR = GRA.curve(j);
                        
                        % Name
                        if (isfield(CUR,'name'))
                            name = string(CUR.name);
                            if (~this.isStringArray(name,1))
                                this.invalidParamError('Graph.curve.name','It must be a string with the name of the curve');
                                status = 0; return;
                            end
                            gra.names(j) = name;
                        else
                            gra.names(j) = sprintf('Curve %d',j);
                        end
                        
                        % Particle X
                        if (isfield(CUR,'particle_x'))
                            if (~ismember(X,global_results))
                                particle_x = CUR.particle_x;
                                if (~this.isIntArray(particle_x,1) || particle_x <= 0 || particle_x > drv.n_particles)
                                    this.invalidParamError('Graph.curve.particle_x','It must be a positive integer corresponding to a valid particle ID');
                                    status = 0; return;
                                end
                                gra.px(j) = particle_x;
                            else
                                this.warnMsg('Graph.curve.particle_x was provided to a curve whose X-axis data is not a particle result. It will be ignored.');
                            end
                        elseif (~ismember(X,global_results))
                            this.missingDataError('Graph.curve.particle_x');
                            status = 0; return;
                        end
                        
                        % Particle Y
                        if (isfield(CUR,'particle_y'))
                            if (~ismember(Y,global_results))
                                particle_y = CUR.particle_y;
                                if (~this.isIntArray(particle_y,1) || particle_y <= 0 || particle_y > drv.n_particles)
                                    this.invalidParamError('Graph.curve.particle_y','It must be a positive integer corresponding to a valid particle ID');
                                    status = 0; return;
                                end
                                gra.py(j) = particle_y;
                            else
                                this.warnMsg('Graph.curve.particle_y was provided to a curve whose Y-axis data is not a particle result. It will be ignored.');
                            end
                        elseif (~ismember(Y,global_results))
                            this.missingDataError('Graph.curve.particle_y');
                            status = 0; return;
                        end
                    end
                else
                    this.warnMsg('A graph with no curve was identified');
                    gra.n_curves = 0;
                end
            end
            
            % Check for graphs with same title
            for i = 1:length(drv.graphs)
                if (length(findobj(drv.graphs,'gtitle',drv.graphs(i).gtitle)) > 1)
                    this.invalidParamError('Repeated graph title.','Graph titles must be unique');
                    status = 0; return;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = getAnimation(this,json,drv)
            status = 1;
            if (~isfield(json,'Animation'))
                return;
            end
            
            for i = 1:length(json.Animation)
                ANM = json.Animation(i);
                
                % Create animation object
                anim = Animation();
                drv.animations(i) = anim;
                
                % Title
                if (isfield(ANM,'title'))
                    title = string(ANM.title);
                    if (~this.isStringArray(title,1))
                        this.invalidParamError('Animation.title','It must be a string with the title of the animation');
                        status = 0; return;
                    end
                    anim.anim_title = title;
                else
                    anim.anim_title = sprintf('Animation %d',i);
                end
                
                % Results colorbar range (for scalar results)
                if (isfield(ANM,'colorbar_range'))
                    range = ANM.colorbar_range;
                    if (~this.isDoubleArray(range,2) || range(1) >= range(2))
                        this.invalidParamError('Animation.colorbar_range','It must be a pair of numeric values: [min,max] where min < max');
                        status = 0; return;
                    end
                    anim.res_range = range;
                end
                
                % Automatic play
                if (isfield(ANM,'auto_play'))
                    play = ANM.auto_play;
                    if (~this.isLogicalArray(play,1))
                        this.invalidParamError('Animation.auto_play','It must be a boolean: true or false');
                        status = 0; return;
                    end
                    anim.play = play;
                end
                
                % Plot particles IDs
                if (isfield(ANM,'particle_ids'))
                    pids = ANM.particle_ids;
                    if (~this.isLogicalArray(pids,1))
                        this.invalidParamError('Animation.particle_id','It must be a boolean: true or false');
                        status = 0; return;
                    end
                    anim.pids = pids;
                end
                
                % Bounding box
                if (isfield(ANM,'bounding_box'))
                    bbox = ANM.bounding_box;
                    if (~this.isDoubleArray(bbox,4) || bbox(1) >= bbox(2) || bbox(3) >= bbox(4))
                        this.invalidParamError('Animation.bounding_box','It must be a numeric array with four values: Xmin, Xmax, Ymin, Ymax');
                        status = 0; return;
                    end
                    anim.bbox = bbox;
                else
                    this.warnMsg('Animation has no fixed limits (bounding box). It may lead to unsatisfactory animation behavior.');
                end
                
                % Array of possible results
                results_general = ["radius","mass",...
                                   "motion","coordinate_x","coordinate_y","orientation"];
                results_mech    = ["force_vector","force_modulus","force_x","force_y","torque",...
                                   "velocity_vector","velocity_modulus","velocity_x","velocity_y","velocity_rot",...
                                   "acceleration_vector","acceleration_modulus","acceleration_x","acceleration_y","acceleration_rot"];
                results_therm   = ["heat_rate","temperature"];
                
                % Result type
                if (~isfield(ANM,'result'))
                    this.missingDataError('Animation.result');
                    status = 0; return;
                end
                result = string(ANM.result);
                if (~this.isStringArray(result,1) ||...
                   (~ismember(result,results_general) && ~ismember(result,results_mech) && ~ismember(result,results_therm)))
                    this.invalidParamError('Animation.result','Available result options can be checked in the documentation');
                    status = 0; return;
                elseif (drv.type == drv.MECHANICAL && ismember(result,results_therm))
                    this.invalidParamError('Animation.result','Available result options can be checked in the documentation');
                    status = 0; return;
                elseif (drv.type == drv.THERMAL && ismember(result,results_mech))
                    this.invalidParamError('Animation.result','Available result options can be checked in the documentation');
                    status = 0; return;
                elseif (strcmp(result,'radius'))
                    anim.res_type = drv.result.RADIUS;
                    drv.result.has_radius = true;
                elseif (strcmp(result,'mass'))
                    anim.res_type = drv.result.MASS;
                    drv.result.has_mass = true;
                elseif (strcmp(result,'motion'))
                    anim.res_type = drv.result.MOTION;
                    drv.result.has_orientation = true;
                elseif (strcmp(result,'coordinate_x'))
                    anim.res_type = drv.result.COORDINATE_X;
                    drv.result.has_coord_x = true;
                elseif (strcmp(result,'coordinate_y'))
                    anim.res_type = drv.result.COORDINATE_Y;
                    drv.result.has_coord_y = true;
                elseif (strcmp(result,'orientation'))
                    anim.res_type = drv.result.ORIENTATION;
                    drv.result.has_orientation = true;
                elseif (strcmp(result,'force_vector'))
                    anim.res_type = drv.result.FORCE_VEC;
                    drv.result.has_force_x = true;
                    drv.result.has_force_y = true;
                elseif (strcmp(result,'force_modulus'))
                    anim.res_type = drv.result.FORCE_MOD;
                    drv.result.has_force_x = true;
                    drv.result.has_force_y = true;
                elseif (strcmp(result,'force_x'))
                    anim.res_type = drv.result.FORCE_X;
                    drv.result.has_force_x = true;
                elseif (strcmp(result,'force_y'))
                    anim.res_type = drv.result.FORCE_Y;
                    drv.result.has_force_y = true;
                elseif (strcmp(result,'torque'))
                    anim.res_type = drv.result.TORQUE;
                    drv.result.has_torque = true;
                elseif (strcmp(result,'velocity_vector'))
                    anim.res_type = drv.result.VELOCITY_VEC;
                    drv.result.has_velocity_x = true;
                    drv.result.has_velocity_y = true;
                elseif (strcmp(result,'velocity_modulus'))
                    anim.res_type = drv.result.VELOCITY_MOD;
                    drv.result.has_velocity_x = true;
                    drv.result.has_velocity_y = true;
                elseif (strcmp(result,'velocity_x'))
                    anim.res_type = drv.result.VELOCITY_X;
                    drv.result.has_velocity_x = true;
                elseif (strcmp(result,'velocity_y'))
                    anim.res_type = drv.result.VELOCITY_Y;
                    drv.result.has_velocity_y = true;
                elseif (strcmp(result,'velocity_rot'))
                    anim.res_type = drv.result.VELOCITY_ROT;
                    drv.result.has_velocity_rot = true;
                elseif (strcmp(result,'acceleration_vector'))
                    anim.res_type = drv.result.ACCELERATION_VEC;
                    drv.result.has_acceleration_x = true;
                    drv.result.has_acceleration_y = true;
                elseif (strcmp(result,'acceleration_modulus'))
                    anim.res_type = drv.result.ACCELERATION_MOD;
                    drv.result.has_acceleration_x = true;
                    drv.result.has_acceleration_y = true;
                elseif (strcmp(result,'acceleration_x'))
                    anim.res_type = drv.result.ACCELERATION_X;
                    drv.result.has_acceleration_x = true;
                elseif (strcmp(result,'acceleration_y'))
                    anim.res_type = drv.result.ACCELERATION_Y;
                    drv.result.has_acceleration_y = true;
                elseif (strcmp(result,'acceleration_rot'))
                    anim.res_type = drv.result.ACCELERATION_ROT;
                    drv.result.has_acceleration_rot = true;
                elseif (strcmp(result,'temperature'))
                    anim.res_type = drv.result.TEMPERATURE;
                    drv.result.has_temperature = true;
                    drv.result.has_wall_temperature = true;
                elseif (strcmp(result,'heat_rate'))
                    anim.res_type = drv.result.HEAT_RATE;
                    drv.result.has_heat_rate = true;
                end
            end
            
            % Check for animations with same title
            for i = 1:length(drv.animations)
                if (length(findobj(drv.animations,'anim_title',drv.animations(i).anim_title)) > 1)
                    this.invalidParamError('Repeated animation title.','Animation titles must be unique');
                    status = 0; return;
                end
            end
        end
    end
    
    %% Public methods: model parts file
    methods
        %------------------------------------------------------------------
        function status = readParticlesSphere(this,fid,drv)
            status = 1;
            
            % Total number of sphere particles
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                this.invalidModelError('PARTICLES.SPHERE','Total number of particles must be a positive integer');
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
                if (length(values) ~= 5)
                    this.invalidModelError('PARTICLES.SPHERE','Sphere particles require 5 parameters: ID, coord X, coord Y, orientation, radius');
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    this.invalidModelError('PARTICLES.SPHERE','ID number of particles must be a positive integer');
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~this.isDoubleArray(coord,2))
                    this.invalidModelError('PARTICLES.SPHERE','Coordinates of sphere particles must be a pair of numeric values');
                    status = 0; return;
                end
                
                % Orientation angle
                orient = values(4);
                if (~this.isDoubleArray(orient,1))
                    this.invalidModelError('PARTICLES.SPHERE','Orientation of sphere particles must be a numeric value');
                    status = 0; return;
                end
                
                % Radius
                radius = values(5);
                if (~this.isDoubleArray(radius,1) || radius <= 0)
                    this.invalidModelError('PARTICLES.SPHERE','Radius of sphere particles must be a positive value');
                    status = 0; return;
                end
                
                % Create new particle object
                particle        = Particle_Sphere();
                particle.id     = id;
                particle.coord  = coord;
                particle.orient = orient;
                particle.radius = radius;
                
                % Store handle to particle object
                if (id <= length(drv.particles) && ~isempty(drv.particles(id).id))
                    this.invalidModelError('PARTICLES.SPHERE','Particles IDs cannot be repeated');
                    status = 0; return;
                end
                drv.particles(id) = particle;
            end
            
            if (i < n)
                this.invalidModelError('PARTICLES.SPHERE','Total number of sphere particles is incompatible with provided data');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readParticlesCylinder(this,fid,drv)
            status = 1;
            
            % Total number of cylinder particles
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                this.invalidModelError('PARTICLES.CYLINDER','Total number of particles must be a positive integer');
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
                if (length(values) ~= 6)
                    this.invalidModelError('PARTICLES.CYLINDER','Cylinder particles require 6 parameters: ID, coord X, coord Y, orientation, length, radius');
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    this.invalidModelError('PARTICLES.CYLINDER','ID number of particles must be a positive integer');
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~this.isDoubleArray(coord,2))
                    this.invalidModelError('PARTICLES.CYLINDER','Coordinates of cylinder particles must be a pair of numeric values');
                    status = 0; return;
                end
                
                % Orientation angle
                orient = values(4);
                if (~this.isDoubleArray(orient,1))
                    this.invalidModelError('PARTICLES.CYLINDER','Orientation of cylinder particles must be a numeric value');
                    status = 0; return;
                end
                
                % Length
                length = values(5);
                if (~this.isDoubleArray(length,1) || length <= 0)
                    this.invalidModelError('PARTICLES.CYLINDER','Length of cylinder particles must be a positive value');
                    status = 0; return;
                end
                
                % Radius
                radius = values(6);
                if (~this.isDoubleArray(radius,1) || radius <= 0)
                    this.invalidModelError('PARTICLES.CYLINDER','Radius of cylinder particles must be a positive value');
                    status = 0; return;
                end
                
                % Create new particle object
                particle        = Particle_Cylinder();
                particle.id     = id;
                particle.coord  = coord;
                particle.orient = orient;
                particle.len    = length;
                particle.radius = radius;
                
                % Store handle to particle object
                if (id <= length(drv.particles) && ~isempty(drv.particles(id).id))
                    this.invalidModelError('PARTICLES.CYLINDER','Particles IDs cannot be repeated');
                    status = 0; return;
                end
                drv.particles(id) = particle;
            end
            
            if (i < n)
                this.invalidModelError('PARTICLES.CYLINDER','Total number of cylinder particles is incompatible with provided data');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsLine(this,fid,drv)
            status = 1;
            
            % Total number of line walls
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                this.invalidModelError('WALLS.LINE','Total number of walls must be a positive integer');
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
                    this.invalidModelError('WALLS.LINE','Line walls require 5 parameters: ID, coord X1, coord Y1, coord X2, coord Y2');
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    this.invalidModelError('WALLS.LINE','ID number of walls must be a positive integer');
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:5);
                if (~this.isDoubleArray(coord,4))
                    this.invalidModelError('WALLS.LINE','Coordinates of line walls must be two pairs of numeric values: X1,Y1,X2,Y2');
                    status = 0; return;
                end
                
                % Create new wall object
                wall           = Wall_Line();
                wall.id        = id;
                wall.coord_ini = coord(1:2);
                wall.coord_end = coord(3:4);
                wall.len       = norm(wall.coord_end-wall.coord_ini);
                
                % Store handle to wall object
                if (id <= length(drv.walls) && ~isempty(drv.walls(id).id))
                    this.invalidModelError('WALLS.LINE','Walls IDs cannot be repeated');
                    status = 0; return;
                end
                drv.walls(id) = wall;
            end
            
            if (i < n)
                this.invalidModelError('WALLS.LINE','Total number of line walls is incompatible with provided data');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = readWallsCircle(this,fid,drv)
            status = 1;
            
            % Total number of circle walls
            n = fscanf(fid,'%d',1);
            if (~this.isIntArray(n,1) || n < 0)
                this.invalidModelError('WALLS.CIRCLE','Total number of walls must be a positive integer');
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
                    this.invalidModelError('WALLS.CIRCLE','Circle walls require 4 parameters: ID, center coord X, center coord Y, radius');
                    status = 0; return;
                end
                
                % ID number
                id = values(1);
                if (~this.isIntArray(id,1) || id <= 0)
                    this.invalidModelError('WALLS.CIRCLE','ID number of walls must be a positive integer');
                    status = 0; return;
                end
                
                % Coordinates
                coord = values(2:3);
                if (~this.isDoubleArray(coord,2))
                    this.invalidModelError('WALLS.CIRCLE','Coordinates of circle walls must be a pair of numeric values: X,Y\n');
                    status = 0; return;
                end
                
                % Radius
                radius = values(4);
                if (~this.isDoubleArray(radius,1) || radius <= 0)
                    this.invalidModelError('WALLS.CIRCLE','Radius of circle walls must be a positive value\n');
                    status = 0; return;
                end
                
                % Create new wall object
                wall        = Wall_Circle();
                wall.id     = id;
                wall.center = coord;
                wall.radius = radius;
                
                % Store handle to wall object
                if (id <= length(drv.walls) && ~isempty(drv.walls(id).id))
                    this.invalidModelError('WALLS.CIRCLE','Walls IDs cannot be repeated');
                    status = 0; return;
                end
                drv.walls(id) = wall;
            end
            
            if (i < n)
                this.invalidModelError('WALLS.isempty','Total number of circle walls is incompatible with provided data');
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
            reserved = ["PARTICLES","WALLS"];
            
            % Model part name
            line = deblank(fgetl(fid));
            if (isempty(line) || isnumeric(line))
                this.invalidModelError('MODELPART','Name of a model part was not provided or is invalid');
                status = 0; return;
            end
            line = string(regexp(line,' ','split'));
            if (length(line) ~= 2 || ~strcmp(line(1),'NAME') || ismember(line(2),reserved))
                this.invalidModelError('MODELPART','Name of a model part was not provided or is invalid');
                status = 0; return;
            end
            mp.name = line(2);
            
            % Model part components
            c = 0;
            while true
                % Get title and total number of components
                line = deblank(fgetl(fid));
                if (isempty(line) || isnumeric(line))
                    break;
                end
                line = string(regexp(line,' ','split'));
                if (~ismember(line(1),reserved))
                    this.invalidModelError('MODELPART','Modelpart can contain only two fields after its name: PARTICLES and WALLS');
                    status = 0; return;
                elseif (length(line) ~= 2 || isnan(str2double(line(2))) || floor(str2double(line(2))) ~= ceil(str2double(line(2))) || str2double(line(2)) < 0)
                    fprintf(2,'Invalid data in model parts file: Number of %s of MODELPART %s was not provided correctly.\n',line(1),mp.name);
                    status = 0; return;
                end
                
                % PARTICLES
                if (strcmp(line(1),'PARTICLES'))
                    c = c + 1;
                    
                    % Store number of particles
                    np = str2double(line(2));
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
                elseif (strcmp(line(1),'WALLS'))
                    c = c + 1;
                    
                    % Store number of walls
                    nw = str2double(line(2));
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
                this.warnMsg('Empty model part was created.');
            end
        end
    end
    
    %% Public methods: interactions models
    methods
        %------------------------------------------------------------------
        function status = interactContactForceNormal(this,IM,drv)
            status = 1;
            if (drv.type == drv.THERMAL)
                return;
            elseif (~isfield(IM,'contact_force_normal'))
                this.warnMsg('No model for contact normal force was identified. This force component will not be considered.');
                return;
            end
            
            % Model parameters
            if (~isfield(IM.contact_force_normal,'model'))
                this.missingDataError('InteractionModel.contact_force_normal.model');
                status = 0; return;
            end
            model = string(IM.contact_force_normal.model);
            if (~this.isStringArray(model,1)            ||...
               (~strcmp(model,'viscoelastic_linear')    &&...
                ~strcmp(model,'viscoelastic_nonlinear') &&...
                ~strcmp(model,'elastoplastic_linear')))
                this.invalidOptError('InteractionModel.contact_force_normal.model','viscoelastic_linear, viscoelastic_nonlinear, elastoplastic_linear');
                status = 0; return;
            end
            
            % Call sub-method for each type of model
            if (strcmp(model,'viscoelastic_linear'))
                if (~this.contactForceNormal_ViscoElasticLinear(IM.contact_force_normal,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'viscoelastic_nonlinear'))
                if (~this.contactForceNormal_ViscoElasticNonlinear(IM.contact_force_normal,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'elastoplastic_linear'))
                if (~this.contactForceNormal_ElastoPlasticLinear(IM.contact_force_normal,drv))
                    status = 0;
                    return;
                end
            end
            
            % Coefficient of restitution
            if (~isfield(IM.contact_force_normal,'restitution_coeff'))
                this.missingDataError('InteractionModel.contact_force_normal.restitution_coeff');
                status = 0; return;
            end
            rest = IM.contact_force_normal.restitution_coeff;
            if (~this.isDoubleArray(rest,1))
                this.invalidParamError('InteractionModel.contact_force_normal.restitution_coeff','It must be a numeric value');
            elseif (rest < 0 || rest > 1)
                this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.restitution_coeff.');
            end
            drv.search.b_interact.cforcen.restitution = rest;
        end
        
        %------------------------------------------------------------------
        function status = interactContactForceTangent(this,IM,drv)
            status = 1;
            if (drv.type == drv.THERMAL)
                return;
            elseif (~isfield(IM,'contact_force_tangent'))
                this.warnMsg('No model for contact tangent force was identified. This force component will not be considered.');
                return;
            end
            
            % Model parameters
            if (~isfield(IM.contact_force_tangent,'model'))
                this.missingDataError('InteractionModel.contact_force_tangent.model');
                status = 0; return;
            end
            model = string(IM.contact_force_tangent.model);
            if (~this.isStringArray(model,1)    ||...
               (~strcmp(model,'simple_slider')  &&...
                ~strcmp(model,'simple_spring')  &&...
                ~strcmp(model,'simple_dashpot') &&...
                ~strcmp(model,'spring_slider')  &&...
                ~strcmp(model,'dashpot_slider') &&...
                ~strcmp(model,'sds_linear')     &&...
                ~strcmp(model,'sds_nonlinear')))
                this.invalidOptError('InteractionModel.contact_force_tangent.model','simple_slider, simple_spring, simple_dashpot, spring_slider, dashpot_slider, sds_linear, sds_nonlinear');
                status = 0; return;
            end
            
            % Call sub-method for each type of model
            if (strcmp(model,'simple_slider'))
                if (~this.contactForceTangent_SimpleSlider(IM.contact_force_tangent,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'simple_spring'))
                if (~this.contactForceTangent_SimpleSpring(IM.contact_force_tangent,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'simple_dashpot'))
                if (~this.contactForceTangent_SimpleDashpot(IM.contact_force_tangent,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'spring_slider'))
                if (~this.contactForceTangent_SpringSlider(IM.contact_force_tangent,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'dashpot_slider'))
                if (~this.contactForceTangent_DashpotSlider(IM.contact_force_tangent,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'sds_linear'))
                if (~this.contactForceTangent_SDSLinear(IM.contact_force_tangent,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'sds_nonlinear'))
                if (~this.contactForceTangent_SDSNonlinear(IM.contact_force_tangent,drv))
                    status = 0;
                    return;
                end
            end
            
            % Coefficient of restitution
            if (isfield(IM.contact_force_tangent,'restitution_coeff'))
                rest = IM.contact_force_tangent.restitution_coeff;
                if (~this.isDoubleArray(rest,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.restitution_coeff','It must be a numeric value');
                elseif (rest < 0 || rest > 1)
                    this.warnMsg('Unphysical value found for InteractionModel.contact_force_tangent.restitution_coeff.');
                end
                drv.search.b_interact.cforcet.restitution = rest;
            end
        end
        
        %------------------------------------------------------------------
        function status = interactRollResist(this,IM,drv)
            status = 1;
            if (drv.type == drv.THERMAL || ~isfield(IM,'rolling_resistance'))
                return;
            end
            
            % Model parameters
            if (~isfield(IM.rolling_resistance,'model'))
                this.missingDataError('InteractionModel.rolling_resistance.model');
                status = 0; return;
            end
            model = string(IM.rolling_resistance.model);
            if (~this.isStringArray(model,1) ||...
               (~strcmp(model,'constant')    &&...
                ~strcmp(model,'viscous')))
                this.invalidOptError('InteractionModel.rolling_resistance.model','constant, viscous');
                status = 0; return;
            end
            
            % Call sub-method for each type of model
            if (strcmp(model,'constant'))
                if (~this.rollingResist_Constant(IM.rolling_resistance,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'viscous'))
                if (~this.rollingResist_Viscous(IM.rolling_resistance,drv))
                    status = 0;
                    return;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = interactAreaCorrection(this,IM,drv)
            status = 1;
            if (~isfield(IM,'area_correction'))
                return;
            end
            
            % Model parameters
            if (~isfield(IM.area_correction,'model'))
                this.missingDataError('InteractionModel.area_correction.model');
                status = 0; return;
            end
            model = string(IM.area_correction.model);
            if (~this.isStringArray(model,1) ||...
               (~strcmp(model,'ZYZ')  &&...
                ~strcmp(model,'LMLB') &&...
                ~strcmp(model,'MPMH')))
                this.invalidOptError('InteractionModel.area_correction.model','ZYZ, LMLB, MPMH');
                status = 0; return;
            end
            
            % Create object
            if (strcmp(model,'ZYZ'))
                drv.search.b_interact.corarea = AreaCorrect_ZYZ();
            elseif (strcmp(model,'LMLB'))
                drv.search.b_interact.corarea = AreaCorrect_LMLB();
            elseif (strcmp(model,'MPMH'))
                drv.search.b_interact.corarea = AreaCorrect_MPMH();
            end
        end
        
        %------------------------------------------------------------------
        function status = interactConductionDirect(this,IM,drv)
            status = 1;
            if (drv.type == drv.MECHANICAL)
                return;
            elseif (~isfield(IM,'direct_conduction'))
                this.warnMsg('No model for direct thermal conduction was identified. This heat transfer mechanism will not be considered.');
                return;
            end
            
            % Model parameters
            if (~isfield(IM.direct_conduction,'model'))
                this.missingDataError('InteractionModel.direct_conduction.model');
                status = 0; return;
            end
            model = string(IM.direct_conduction.model);
            if (~this.isStringArray(model,1)  ||...
               (~strcmp(model,'bob')          &&...
                ~strcmp(model,'thermal_pipe') &&...
                ~strcmp(model,'collisional')))
                this.invalidOptError('InteractionModel.direct_conduction.model','bob, thermal_pipe, collisional');
                status = 0; return;
            end
            
            % Create object
            if (strcmp(model,'bob'))
                drv.search.b_interact.dconduc = ConductionDirect_BOB();
            elseif (strcmp(model,'thermal_pipe'))
                drv.search.b_interact.dconduc = ConductionDirect_Pipe();
            elseif (strcmp(model,'collisional'))
                drv.search.b_interact.dconduc = ConductionDirect_Collisional();
            end
        end
        
        %------------------------------------------------------------------
        function status = interactConductionIndirect(this,IM,drv)
            status = 1;
            if (drv.type == drv.MECHANICAL || ~isfield(IM,'indirect_conduction'))
                return;
            end
            
            % Model parameters
            if (~isfield(IM.indirect_conduction,'model'))
                this.missingDataError('InteractionModel.indirect_conduction.model');
                status = 0; return;
            end
            model = string(IM.indirect_conduction.model);
            if (~this.isStringArray(model,1) ||...
               (~strcmp(model,'vononoi_a')   &&...
                ~strcmp(model,'vononoi_b')   &&...
                ~strcmp(model,'surrounding_layer')))
                this.invalidOptError('InteractionModel.indirect_conduction.model','vononoi_a, vononoi_b, surrounding_layer');
                status = 0; return;
            end
            
            % Call sub-method for each type of model
            if (strcmp(model,'vononoi_a'))
                if (~this.indirectConduction_VoronoiA(IM.indirect_conduction,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'vononoi_b'))
                if (~this.indirectConduction_VoronoiB(IM.indirect_conduction,drv))
                    status = 0;
                    return;
                end
            elseif (strcmp(model,'surrounding_layer'))
                if (~this.indirectConduction_SurrLayer(IM.indirect_conduction,drv))
                    status = 0;
                    return;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceNormal_ViscoElasticLinear(this,CFN,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcen = ContactForceN_ViscoElasticLinear();
            
            % Stiffness coefficient value
            if (isfield(CFN,'stiff_coeff'))
                val = CFN.stiff_coeff;
                if (~this.isDoubleArray(val,1))
                    this.invalidParamError('InteractionModel.contact_force_normal.stiff_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (val <= 0)
                    this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.stiff_coeff.');
                end
                drv.search.b_interact.cforcen.stiff = val;
                drv.search.b_interact.cforcen.stiff_formula = drv.search.b_interact.cforcen.NONE_STIFF;
            
            % Stiffness formulation
            elseif (isfield(CFN,'stiff_formula'))
                if (~this.isStringArray(CFN.stiff_formula,1) ||...
                   (~strcmp(CFN.stiff_formula,'energy')      &&...
                    ~strcmp(CFN.stiff_formula,'overlap')     &&...
                    ~strcmp(CFN.stiff_formula,'time')))
                    this.invalidOptError('InteractionModel.contact_force_normal.stiff_formula','energy, overlap, time');
                    status = 0; return;
                end
                if (strcmp(CFN.stiff_formula,'energy'))
                    drv.search.b_interact.cforcen.stiff_formula = drv.search.b_interact.cforcen.ENERGY;
                elseif (strcmp(CFN.stiff_formula,'overlap'))
                    drv.search.b_interact.cforcen.stiff_formula = drv.search.b_interact.cforcen.OVERLAP;
                elseif (strcmp(CFN.stiff_formula,'time'))
                    drv.search.b_interact.cforcen.stiff_formula = drv.search.b_interact.cforcen.TIME;
                end
            end
            
            % Check which stiffness options were provided
            if (isfield(CFN,'stiff_coeff') &&...
                isfield(CFN,'stiff_formula'))
                this.warnMsg('The value of InteractionModel.contact_force_normal.stiff_coeff was provided, so InteractionModel.contact_force_normal.stiff_formula will be ignored.');
            elseif (~isfield(CFN,'stiff_coeff') &&...
                    ~isfield(CFN,'stiff_formula'))
                this.warnMsg('Nor InteractionModel.contact_force_normal.stiff_coeff neither InteractionModel.contact_force_normal.stiff_formula was provided, so energy formulation will be assumed.');
            end
            
            % Damping coefficient value
            if (isfield(CFN,'damping_coeff'))
                val = CFN.damping_coeff;
                if (~this.isDoubleArray(val,1))
                    this.invalidParamError('InteractionModel.contact_force_normal.damping_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (val <= 0)
                    this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.damping_coeff.');
                end
                drv.search.b_interact.cforcen.damp = val;
            end
            
            % Artificial cohesion
            if (isfield(CFN,'remove_artificial_cohesion'))
                if (~this.isLogicalArray(CFN.remove_artificial_cohesion,1))
                    this.invalidParamError('InteractionModel.contact_force_normal.remove_artificial_cohesion','It must be a boolean: true or false');
                    status = 0; return;
                end
                drv.search.b_interact.cforcen.remove_cohesion = CFN.remove_artificial_cohesion;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceNormal_ViscoElasticNonlinear(this,CFN,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcen = ContactForceN_ViscoElasticNonlinear();
            
            % Damping formulation
            if (isfield(CFN,'damping_formula'))
                if (~this.isStringArray(CFN.damping_formula,1)    ||...
                   (~strcmp(CFN.damping_formula,'critical_ratio') &&...
                    ~strcmp(CFN.damping_formula,'TTI')            &&...
                    ~strcmp(CFN.damping_formula,'KK')             &&...
                    ~strcmp(CFN.damping_formula,'LH')))
                    this.invalidOptError('InteractionModel.contact_force_normal.damping_formula','critical_ratio, TTI, KK, LH');
                    status = 0; return;
                end
                
                if (strcmp(CFN.damping_formula,'critical_ratio'))
                    drv.search.b_interact.cforcen.damp_formula = drv.search.b_interact.cforcen.CRITICAL_RATIO;
                    
                    % Critical damping ratio (mandatory)
                    if (~isfield(CFN,'ratio'))
                        this.missingDataError('InteractionModel.contact_force_normal.ratio');
                        status = 0; return;
                    end
                    val = CFN.ratio;
                    if (~this.isDoubleArray(val,1))
                        this.invalidParamError('InteractionModel.contact_force_normal.ratio','It must be a numeric value');
                        status = 0; return;
                    elseif (val < 0)
                        this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.ratio.');
                    end
                    drv.search.b_interact.cforcen.damp_ratio = val;
                    
                elseif (strcmp(CFN.damping_formula,'TTI'))
                    drv.search.b_interact.cforcen.damp_formula = drv.search.b_interact.cforcen.TTI;
                    
                    % Damping coefficient value (optional)
                    if (isfield(CFN,'damping_coeff'))
                        val = CFN.damping_coeff;
                        if (~this.isDoubleArray(val,1))
                            this.invalidParamError('InteractionModel.contact_force_normal.damping_coeff','It must be a numeric value');
                            status = 0; return;
                        elseif (val <= 0)
                            this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.damping_coeff.');
                        end
                        drv.search.b_interact.cforcen.damp = val;
                    end
                    
                elseif (strcmp(CFN.damping_formula,'KK'))
                    drv.search.b_interact.cforcen.damp_formula = drv.search.b_interact.cforcen.KK;
                    
                    % Damping coefficient value (mandatory)
                    if (~isfield(CFN,'damping_coeff'))
                        this.missingDataError('InteractionModel.contact_force_normal.damping_coeff');
                        status = 0; return;
                    end
                    val = CFN.damping_coeff;
                    if (~this.isDoubleArray(val,1))
                        this.invalidParamError('InteractionModel.contact_force_normal.damping_coeff','It must be a numeric value');
                        status = 0; return;
                    elseif (val <= 0)
                        this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.damping_coeff.');
                    end
                    drv.search.b_interact.cforcen.damp = val;
                    
                elseif (strcmp(CFN.damping_formula,'LH'))
                    drv.search.b_interact.cforcen.damp_formula = drv.search.b_interact.cforcen.LH;
                    
                    % Damping coefficient value (mandatory)
                    if (~isfield(CFN,'damping_coeff'))
                        this.missingDataError('InteractionModel.contact_force_normal.damping_coeff');
                        status = 0; return;
                    end
                    val = CFN.damping_coeff;
                    if (~this.isDoubleArray(val,1))
                        this.invalidParamError('InteractionModel.contact_force_normal.damping_coeff','It must be a numeric value');
                        status = 0; return;
                    elseif (val <= 0)
                        this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.damping_coeff.');
                    end
                    drv.search.b_interact.cforcen.damp = val;
                end
                
            % Damping coefficient value
            elseif (isfield(CFN,'damping_coeff'))
                this.warnMsg('The value of InteractionModel.contact_force_normal.damping_coeff was provided with no formulation, so a linear viscous damping will be assumed.');
                val = CFN.damping_coeff;
                if (~this.isDoubleArray(val,1))
                    this.invalidParamError('InteractionModel.contact_force_normal.damping_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (val <= 0)
                    this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.damping_coeff.');
                end
                drv.search.b_interact.cforcen.damp = val;
                drv.search.b_interact.cforcen.damp_formula = drv.search.b_interact.cforcen.NONE_DAMP;
            end
            
            % Artificial cohesion
            if (isfield(CFN,'remove_artificial_cohesion'))
                if (~this.isLogicalArray(CFN.remove_artificial_cohesion,1))
                    this.invalidParamError('InteractionModel.contact_force_normal.remove_artificial_cohesion','It must be a boolean: true or false');
                    status = 0; return;
                end
                drv.search.b_interact.cforcen.remove_cohesion = CFN.remove_artificial_cohesion;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceNormal_ElastoPlasticLinear(this,CFN,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcen = ContactForceN_ElastoPlasticLinear();
            
            % Loading stiffness coefficient value
            if (isfield(CFN,'stiff_coeff'))
                val = CFN.stiff_coeff;
                if (~this.isDoubleArray(val,1))
                    this.invalidParamError('InteractionModel.contact_force_normal.stiff_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (val <= 0)
                    this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.stiff_coeff.');
                end
                drv.search.b_interact.cforcen.stiff = val;
                drv.search.b_interact.cforcen.load_stiff_formula = drv.search.b_interact.cforcen.NONE_STIFF;
            
            % Loading stiffness formulation
            elseif (isfield(CFN,'load_stiff_formula'))
                if (~this.isStringArray(CFN.load_stiff_formula,1) ||...
                   (~strcmp(CFN.load_stiff_formula,'energy')      &&...
                    ~strcmp(CFN.load_stiff_formula,'overlap')     &&...
                    ~strcmp(CFN.load_stiff_formula,'time')))
                    this.invalidOptError('InteractionModel.contact_force_normal.load_stiff_formula','energy, overlap, time');
                    status = 0; return;
                end
                if (strcmp(CFN.load_stiff_formula,'energy'))
                    drv.search.b_interact.cforcen.load_stiff_formula = drv.search.b_interact.cforcen.ENERGY;
                elseif (strcmp(CFN.load_stiff_formula,'overlap'))
                    drv.search.b_interact.cforcen.load_stiff_formula = drv.search.b_interact.cforcen.OVERLAP;
                elseif (strcmp(CFN.load_stiff_formula,'time'))
                    drv.search.b_interact.cforcen.load_stiff_formula = drv.search.b_interact.cforcen.TIME;
                end
            end
            
            % Check which loading stiffness options were provided
            if (isfield(CFN,'stiff_coeff') &&...
                isfield(CFN,'load_stiff_formula'))
                this.warnMsg('The value of InteractionModel.contact_force_normal.stiff_coeff was provided, so InteractionModel.contact_force_normal.load_stiff_formula will be ignored.');
            elseif (~isfield(CFN,'stiff_coeff') &&...
                    ~isfield(CFN,'load_stiff_formula'))
                this.warnMsg('Nor InteractionModel.contact_force_normal.stiff_coeff neither InteractionModel.contact_force_normal.load_stiff_formula was provided, so energy formulation will be assumed.');
            end
            
            % Unloading stiffness formulation
            if (isfield(CFN,'unload_stiff_formula'))
                if (~this.isStringArray(CFN.unload_stiff_formula,1) ||...
                   (~strcmp(CFN.unload_stiff_formula,'constant')    &&...
                    ~strcmp(CFN.unload_stiff_formula,'variable')))
                    this.invalidOptError('InteractionModel.contact_force_normal.unload_stiff_formula','constant, variable');
                    status = 0; return;
                end
                if (strcmp(CFN.unload_stiff_formula,'constant'))
                    drv.search.b_interact.cforcen.unload_stiff_formula = drv.search.b_interact.cforcen.CONSTANT;
                    
                elseif (strcmp(CFN.unload_stiff_formula,'variable'))
                    drv.search.b_interact.cforcen.unload_stiff_formula = drv.search.b_interact.cforcen.VARIABLE;
                    
                    % Variable unload stiffness coefficient parameter
                    if (~isfield(CFN,'unload_param'))
                        this.missingDataError('InteractionModel.contact_force_normal.unload_param');
                        status = 0; return;
                    end
                    unload_param = CFN.unload_param;
                    if (~this.isDoubleArray(unload_param,1))
                        this.invalidParamError('InteractionModel.contact_force_normal.unload_param','It must be a numeric value');
                        status = 0; return;
                    elseif (unload_param <= 0)
                        this.warnMsg('Unphysical value found for InteractionModel.contact_force_normal.unload_param.');
                    end
                    drv.search.b_interact.cforcen.unload_param = unload_param;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceTangent_SimpleSlider(this,CFT,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcet = ContactForceT_Slider();
            
            % Friction coefficient value
            if (isfield(CFT,'friction_coeff'))
                if (~this.isDoubleArray(CFT.friction_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.friction_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.friction_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.friction_coeff');
                end
                drv.search.b_interact.cforcet.fric = CFT.friction_coeff;
            else
                this.missingDataError('InteractionModel.contact_force_tangent.friction_coeff');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceTangent_SimpleSpring(this,CFT,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcet = ContactForceT_Spring();
            
            % Stiffness coefficient value
            if (isfield(CFT,'stiff_coeff'))
                if (~this.isDoubleArray(CFT.stiff_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.stiff_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.stiff_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.stiff_coeff');
                end
                drv.search.b_interact.cforcet.stiff = CFT.stiff_coeff;
                drv.search.b_interact.cforcet.auto_stiff = false;
            else
                drv.search.b_interact.cforcet.auto_stiff = true;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceTangent_SimpleDashpot(this,CFT,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcet = ContactForceT_Dashpot();
            
            % Damping coefficient value
            if (isfield(CFT,'damping_coeff'))
                if (~this.isDoubleArray(CFT.damping_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.damping_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.damping_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.damping_coeff');
                end
                drv.search.b_interact.cforcet.damp = CFT.damping_coeff;
            else
                this.missingDataError('InteractionModel.contact_force_tangent.damping_coeff');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceTangent_SpringSlider(this,CFT,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcet = ContactForceT_SpringSlider();
            
            % Stiffness coefficient value
            if (isfield(CFT,'stiff_coeff'))
                if (~this.isDoubleArray(CFT.stiff_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.stiff_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.stiff_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.stiff_coeff');
                end
                drv.search.b_interact.cforcet.stiff = CFT.stiff_coeff;
                drv.search.b_interact.cforcet.auto_stiff = false;
            else
                drv.search.b_interact.cforcet.auto_stiff = true;
            end
            
            % Friction coefficient value
            if (isfield(CFT,'friction_coeff'))
                if (~this.isDoubleArray(CFT.friction_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.friction_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.friction_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.friction_coeff');
                end
                drv.search.b_interact.cforcet.fric = CFT.friction_coeff;
            else
                this.missingDataError('InteractionModel.contact_force_tangent.friction_coeff');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceTangent_DashpotSlider(this,CFT,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcet = ContactForceT_DashpotSlider();
            
            % Damping coefficient value
            if (isfield(CFT,'damping_coeff'))
                if (~this.isDoubleArray(CFT.damping_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.damping_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.damping_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.damping_coeff');
                end
                drv.search.b_interact.cforcet.damp = CFT.damping_coeff;
            else
                this.missingDataError('InteractionModel.contact_force_tangent.damping_coeff');
                status = 0; return;
            end
            
            % Friction coefficient value
            if (isfield(CFT,'friction_coeff'))
                if (~this.isDoubleArray(CFT.friction_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.friction_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.friction_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.friction_coeff');
                end
                drv.search.b_interact.cforcet.fric = CFT.friction_coeff;
            else
                this.missingDataError('InteractionModel.contact_force_tangent.friction_coeff');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceTangent_SDSLinear(this,CFT,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcet = ContactForceT_SDSLinear();
            
            % Stiffness coefficient value
            if (isfield(CFT,'stiff_coeff'))
                if (~this.isDoubleArray(CFT.stiff_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.stiff_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.stiff_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.stiff_coeff');
                end
                drv.search.b_interact.cforcet.stiff = CFT.stiff_coeff;
                drv.search.b_interact.cforcet.auto_stiff = false;
            else
                drv.search.b_interact.cforcet.auto_stiff = true;
            end
            
            % Damping coefficient value
            if (isfield(CFT,'damping_coeff'))
                if (~this.isDoubleArray(CFT.damping_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.damping_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.damping_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.damping_coeff');
                end
                drv.search.b_interact.cforcet.damp = CFT.damping_coeff;
                drv.search.b_interact.cforcet.auto_damp = false;
            else
                drv.search.b_interact.cforcet.auto_damp = true;
            end
            
            % Friction coefficient value
            if (isfield(CFT,'friction_coeff'))
                if (~this.isDoubleArray(CFT.friction_coeff,1))
                    this.invalidParamError('InteractionModel.contact_force_tangent.friction_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (CFT.friction_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.friction_coeff');
                end
                drv.search.b_interact.cforcet.fric = CFT.friction_coeff;
            else
                this.missingDataError('InteractionModel.contact_force_tangent.friction_coeff');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = contactForceTangent_SDSNonlinear(this,CFT,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.cforcet = ContactForceT_SDSNonlinear();
            
            % Formulation
            if (isfield(CFT,'formula'))
                if (~this.isStringArray(CFT.formula,1) ||...
                    ~strcmp(CFT.formula,'DD')  &&...
                    ~strcmp(CFT.formula,'LTH') &&...
                    ~strcmp(CFT.formula,'ZZY') &&...
                    ~strcmp(CFT.formula,'TTI'))
                    this.invalidOptError('InteractionModel.contact_force_tangent.formula','DD, LTH, ZZY, TTI');
                    status = 0; return;
                end
                if (strcmp(CFT.formula,'DD'))
                    drv.search.b_interact.cforcet.formula = drv.search.b_interact.cforcet.DD;
                    
                elseif (strcmp(CFT.formula,'LTH'))
                    drv.search.b_interact.cforcet.formula = drv.search.b_interact.cforcet.LTH;
                    
                    % Damping coefficient value
                    if (isfield(CFT,'damping_coeff'))
                        if (~this.isDoubleArray(CFT.damping_coeff,1))
                            this.invalidParamError('InteractionModel.contact_force_tangent.damping_coeff','It must be a numeric value');
                            status = 0; return;
                        elseif (CFT.damping_coeff <= 0)
                            this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.damping_coeff');
                        end
                        drv.search.b_interact.cforcet.damp = CFT.damping_coeff;
                    else
                        this.missingDataError('InteractionModel.contact_force_tangent.damping_coeff');
                        status = 0; return;
                    end
                    
                elseif (strcmp(CFT.formula,'ZZY'))
                    drv.search.b_interact.cforcet.formula = drv.search.b_interact.cforcet.ZZY;
                    
                    % Damping coefficient value
                    if (isfield(CFT,'damping_coeff'))
                        if (~this.isDoubleArray(CFT.damping_coeff,1))
                            this.invalidParamError('InteractionModel.contact_force_tangent.damping_coeff','It must be a numeric value');
                            status = 0; return;
                        elseif (CFT.damping_coeff <= 0)
                            this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.damping_coeff');
                        end
                        drv.search.b_interact.cforcet.damp = CFT.damping_coeff;
                    else
                        this.missingDataError('InteractionModel.contact_force_tangent.damping_coeff');
                        status = 0; return;
                    end
                    
                elseif (strcmp(CFT.formula,'TTI'))
                    drv.search.b_interact.cforcet.formula = drv.search.b_interact.cforcet.TTI;
                    
                    % Damping coefficient value
                    if (isfield(CFT,'damping_coeff'))
                        if (~this.isDoubleArray(CFT.damping_coeff,1))
                            this.invalidParamError('InteractionModel.contact_force_tangent.damping_coeff','It must be a numeric value');
                            status = 0; return;
                        elseif (CFT.damping_coeff <= 0)
                            this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.damping_coeff');
                        end
                        drv.search.b_interact.cforcet.damp = CFT.damping_coeff;
                        
                    elseif (drv.search.b_interact.cforcen.type ~= drv.search.b_interact.cforcen.VISCOELASTIC_NONLINEAR)
                        this.missingDataError('InteractionModel.contact_force_tangent.damping_coeff');
                        status = 0; return;
                    end
                end
                
                % Friction coefficient value
                if (isfield(CFT,'friction_coeff'))
                    if (~this.isDoubleArray(CFT.friction_coeff,1))
                        this.invalidParamError('InteractionModel.contact_force_tangent.friction_coeff','It must be a numeric value');
                        status = 0; return;
                    elseif (CFT.friction_coeff <= 0)
                        this.warnMsg('Unphysical property value was found for InteractionModel.contact_force_tangent.friction_coeff');
                    end
                    drv.search.b_interact.cforcet.fric = CFT.friction_coeff;
                else
                    this.missingDataError('InteractionModel.contact_force_tangent.friction_coeff');
                    status = 0; return;
                end
            else
                this.missingDataError('InteractionModel.contact_force_tangent.formula');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = rollingResist_Constant(this,RR,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.rollres = RollResist_Constant();
            
            % Rolling resistance coefficient
            if (isfield(RR,'resistance_coeff'))
                if (~this.isDoubleArray(RR.resistance_coeff,1))
                    this.invalidParamError('InteractionModel.rolling_resistance.resistance_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (RR.resistance_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.rolling_resistance.resistance_coeff');
                end
                drv.search.b_interact.rollres.resist = RR.resistance_coeff;
            else
                this.missingDataError('InteractionModel.rolling_resistance.resistance_coeff');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = rollingResist_Viscous(this,RR,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.rollres = RollResist_Viscous();
            
            % Rolling resistance coefficient
            if (isfield(RR,'resistance_coeff'))
                if (~this.isDoubleArray(RR.resistance_coeff,1))
                    this.invalidParamError('InteractionModel.rolling_resistance.resistance_coeff','It must be a numeric value');
                    status = 0; return;
                elseif (RR.resistance_coeff <= 0)
                    this.warnMsg('Unphysical property value was found for InteractionModel.rolling_resistance.resistance_coeff');
                end
                drv.search.b_interact.rollres.resist = RR.resistance_coeff;
            else
                this.missingDataError('InteractionModel.rolling_resistance.resistance_coeff');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = indirectConduction_VoronoiA(this,IC,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.iconduc = ConductionIndirect_VoronoiA();
            
            % Method to compute cells size
            if (isfield(IC,'cell_size_method'))
                method = string(IC.cell_size_method);
                if (~this.isStringArray(method,1)    ||...
                   (~strcmp(model,'voronoi_diagram') &&...
                    ~strcmp(model,'porosity_local')  &&...
                    ~strcmp(model,'porosity_global')))
                    this.invalidOptError('InteractionModel.indirect_conduction.cell_size_method','voronoi_diagram, porosity_local, porosity_global');
                    status = 0; return;
                end
                if (strcmp(method,'voronoi_diagram'))
                    drv.search.b_interact.iconduc.method = drv.search.b_interact.iconduc.VORONOI_DIAGRAM;
                    
                    % Voronoi diagram update frequency
                    if (isfield(IC,'update_frequency'))
                        freq = IC.update_frequency;
                        if (~this.isIntArray(freq,1) || freq < 0)
                            this.invalidParamError('InteractionModel.indirect_conduction.update_frequency','It must be a positive integer');
                            status = 0; return;
                        end
                        drv.vor_freq = freq;
                    else
                        drv.vor_freq = drv.search.freq;
                    end
                    
                elseif (strcmp(method,'porosity_local'))
                    drv.search.b_interact.iconduc.method = drv.search.b_interact.iconduc.POROSITY_LOCAL;
                    
                    % Local porosity update frequency
                    if (isfield(IC,'update_frequency'))
                        freq = IC.update_frequency;
                        if (~this.isIntArray(freq,1) || freq < 0)
                            this.invalidParamError('InteractionModel.indirect_conduction.update_frequency','It must be a positive integer');
                            status = 0; return;
                        end
                        [drv.particles.por_freq] = deal(freq);
                    else
                        [drv.particles.por_freq] = deal(drv.search.freq);
                    end
                    
                elseif (strcmp(method,'porosity_global'))
                    drv.search.b_interact.iconduc.method = drv.search.b_interact.iconduc.POROSITY_GLOBAL;
                    
                    % Global porosity update frequency
                    if (isfield(IC,'update_frequency'))
                        freq = IC.update_frequency;
                        if (~this.isIntArray(freq,1) || freq < 0)
                            this.invalidParamError('InteractionModel.indirect_conduction.update_frequency','It must be a positive integer');
                            status = 0; return;
                        end
                        drv.por_freq = freq;
                    else
                        drv.por_freq = drv.search.freq;
                    end
                    
                    % Alpha radius
                    if (isfield(IC,'alpha_radius'))
                        alpha = IC.alpha_radius;
                        if (~this.isDoubleArray(alpha,1) || alpha < 0)
                            this.invalidParamError('InteractionModel.indirect_conduction.alpha_radius','It must be a positive value');
                            status = 0; return;
                        end
                        drv.alpha = alpha;
                    else
                        drv.alpha = inf; % convex hull
                    end
                end
            end            
            
            % Prescribed global porosity
            if (isfield(IC,'porosity'))
                % Check inconsistency of provided data
                if (~isnan(drv.por_freq))
                    this.warnMsg('A constant global porosity has been provided, so other parameters will be ignored.');
                end
                
                por = IC.porosity;
                if (~this.isDoubleArray(por,1) || por < 0 || por > 1)
                    this.invalidParamError('InteractionModel.indirect_conduction.porosity','It must be a value between 0 and 1');
                    status = 0; return;
                end
                drv.porosity = por;
                drv.por_freq = NaN; % never updates global porosity (keep global value)
            end
            
            % Tollerances for numerical integration
            if (isfield(IC,'tolerance_absolute'))
                if (~this.isDoubleArray(IC.tolerance_absolute,1) || IC.tolerance_absolute <= 0)
                    this.invalidParamError('InteractionModel.indirect_conduction.tolerance_absolute','It must be a positive value');
                    status = 0; return;
                end
                drv.search.b_interact.iconduc.tol_abs = IC.tolerance_absolute;
            end
            if (isfield(IC,'tolerance_relative'))
                if (~this.isDoubleArray(IC.tolerance_relative,1) || IC.tolerance_relative <= 0)
                    this.invalidParamError('InteractionModel.indirect_conduction.tolerance_relative','It must be a positive value');
                    status = 0; return;
                end
                drv.search.b_interact.iconduc.tol_rel = IC.tolerance_relative;
            end
            
            % Cutoff distance (ratio of particles radius)
            if (isfield(IC,'cutoff_distance'))
                if (~this.isDoubleArray(IC.cutoff_distance,1))
                    this.invalidParamError('InteractionModel.indirect_conduction.cutoff_distance','It must be a numeric value');
                    status = 0; return;
                end
                drv.search.cutoff = IC.cutoff_distance;
            else
                drv.search.cutoff = 1;
            end
        end
        
        %------------------------------------------------------------------
        function status = indirectConduction_VoronoiB(this,IC,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.iconduc = ConductionIndirect_VoronoiB();
            
            % Method to compute cells size
            if (isfield(IC,'cell_size_method'))
                method = string(IC.cell_size_method);
                if (~this.isStringArray(method,1)    ||...
                   (~strcmp(model,'voronoi_diagram') &&...
                    ~strcmp(model,'porosity_local')  &&...
                    ~strcmp(model,'porosity_global')))
                    this.invalidOptError('InteractionModel.indirect_conduction.cell_size_method','voronoi_diagram, porosity_local, porosity_global');
                    status = 0; return;
                end
                if (strcmp(method,'voronoi_diagram'))
                    drv.search.b_interact.iconduc.method = drv.search.b_interact.iconduc.VORONOI_DIAGRAM;
                    
                    % Voronoi diagram update frequency
                    if (isfield(IC,'update_frequency'))
                        freq = IC.update_frequency;
                        if (~this.isIntArray(freq,1) || freq < 0)
                            this.invalidParamError('InteractionModel.indirect_conduction.update_frequency','It must be a positive integer');
                            status = 0; return;
                        end
                        drv.vor_freq = freq;
                    else
                        drv.vor_freq = drv.search.freq;
                    end
                    
                elseif (strcmp(method,'porosity_local'))
                    drv.search.b_interact.iconduc.method = drv.search.b_interact.iconduc.POROSITY_LOCAL;
                    
                    % Local porosity update frequency
                    if (isfield(IC,'update_frequency'))
                        freq = IC.update_frequency;
                        if (~this.isIntArray(freq,1) || freq < 0)
                            this.invalidParamError('InteractionModel.indirect_conduction.update_frequency','It must be a positive integer');
                            status = 0; return;
                        end
                        [drv.particles.por_freq] = deal(freq);
                    else
                        [drv.particles.por_freq] = deal(drv.search.freq);
                    end
                    
                elseif (strcmp(method,'porosity_global'))
                    drv.search.b_interact.iconduc.method = drv.search.b_interact.iconduc.POROSITY_GLOBAL;
                    
                    % Global porosity update frequency
                    if (isfield(IC,'update_frequency'))
                        freq = IC.update_frequency;
                        if (~this.isIntArray(freq,1) || freq < 0)
                            this.invalidParamError('InteractionModel.indirect_conduction.update_frequency','It must be a positive integer');
                            status = 0; return;
                        end
                        drv.por_freq = freq;
                    else
                        drv.por_freq = drv.search.freq;
                    end
                    
                    % Alpha radius
                    if (isfield(IC,'alpha_radius'))
                        alpha = IC.alpha_radius;
                        if (~this.isDoubleArray(alpha,1) || alpha < 0)
                            this.invalidParamError('InteractionModel.indirect_conduction.alpha_radius','It must be a positive value');
                            status = 0; return;
                        end
                        drv.alpha = alpha;
                    else
                        drv.alpha = inf; % convex hull
                    end
                end
            end            
            
            % Prescribed global porosity
            if (isfield(IC,'porosity'))
                % Check inconsistency of provided data
                if (~isnan(drv.por_freq))
                    this.warnMsg('A constant global porosity has been provided, so other parameters will be ignored.');
                end
                
                por = IC.porosity;
                if (~this.isDoubleArray(por,1) || por < 0 || por > 1)
                    this.invalidParamError('InteractionModel.indirect_conduction.porosity','It must be a value between 0 and 1');
                    status = 0; return;
                end
                drv.porosity = por;
                drv.por_freq = NaN; % never updates global porosity (keep global value)
            end
            
            % Isothermal core radius
            if (isfield(IC,'core_radius'))
                if (~this.isDoubleArray(IC.core_radius,1) || IC.core_radius <= 0 || IC.core_radius > 1)
                    this.invalidParamError('InteractionModel.indirect_conduction.core_radius','It must be a value between 0 and 1');
                    status = 0; return;
                end
                drv.search.b_interact.iconduc.core = IC.tolerance_absolute;
            end
            
            % Cutoff distance (ratio of particles radius)
            if (isfield(IC,'cutoff_distance'))
                if (~this.isDoubleArray(IC.cutoff_distance,1))
                    this.invalidParamError('InteractionModel.indirect_conduction.cutoff_distance','It must be a numeric value');
                    status = 0; return;
                end
                drv.search.cutoff = IC.cutoff_distance;
            else
                drv.search.cutoff = 1;
            end
        end
        
        %------------------------------------------------------------------
        function status = indirectConduction_SurrLayer(this,IC,drv)
            status = 1;
            
            % Create object
            drv.search.b_interact.iconduc = ConductionIndirect_SurrLayer();
            
            % Surrounding fluid layer thickness (cutoff distance)
            if (isfield(IC,'layer_thick'))
                if (~this.isDoubleArray(IC.layer_thick,1) || IC.layer_thick < 0)
                    this.invalidParamError('InteractionModel.indirect_conduction.layer_thick','It must be a positive value');
                    status = 0; return;
                end
                drv.search.b_interact.iconduc.layer = IC.layer_thick;
            end
            drv.search.cutoff = drv.search.b_interact.iconduc.layer;
            
            % Minimum separation distance
            if (isfield(IC,'min_distance'))
                if (~this.isDoubleArray(IC.min_distance,1) || IC.min_distance <= 0)
                    this.invalidParamError('InteractionModel.indirect_conduction.min_distance','It must be a positive value');
                    status = 0; return;
                end
                drv.search.b_interact.iconduc.dist_min = IC.min_distance;
            end
            
            % Tollerances for numerical integration
            if (isfield(IC,'tolerance_absolute'))
                if (~this.isDoubleArray(IC.tolerance_absolute,1) || IC.tolerance_absolute <= 0)
                    this.invalidParamError('InteractionModel.indirect_conduction.tolerance_absolute','It must be a positive value');
                    status = 0; return;
                end
                drv.search.b_interact.iconduc.tol_abs = IC.tolerance_absolute;
            end
            if (isfield(IC,'tolerance_relative'))
                if (~this.isDoubleArray(IC.tolerance_relative,1) || IC.tolerance_relative <= 0)
                    this.invalidParamError('InteractionModel.indirect_conduction.tolerance_relative','It must be a positive value');
                    status = 0; return;
                end
                drv.search.b_interact.iconduc.tol_rel = IC.tolerance_relative;
            end
        end
    end
    
    %% Public methods: checks
    methods
        %------------------------------------------------------------------
        function status = checkDriver(~,drv)
            status = 1;
            if (isempty(drv.name))
                this.missingDataError('No problem name was provided.');
                status = 0; return;
            end
            if (isempty(drv.search))
                this.missingDataError('No search scheme was provided.');
                status = 0; return;
            elseif (drv.search.type == drv.search.VERLET_LIST)
                Rmax = max([drv.particles.radius]);
                if (drv.search.verlet_dist <= 2*Rmax+drv.search.cutoff)
                    this.warnMsg('Verlet distance may be too small');
                end
            end
            if ((drv.type == drv.MECHANICAL || drv.type == drv.THERMO_MECHANICAL) &&...
                (isempty(drv.scheme_trl) || isempty(drv.scheme_rot)))
                this.missingDataError('No integration scheme for translation/rotation was provided.');
                status = 0; return;
            end
            if ((drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL) &&...
                 isempty(drv.scheme_temp))
                this.missingDataError('No integration scheme for temperature was provided.');
                status = 0; return;
            end
            if (isempty(drv.time_step) && ~drv.auto_step)
                this.missingDataError('No time step was provided.');
                status = 0; return;
            end
            if (isempty(drv.max_time) && isempty(drv.max_step))
                this.missingDataError('No maximum time and steps were provided.');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = checkMaterials(this,drv)
            status = 1;
            for i = 1:drv.n_materials
                m = drv.materials(i);
                
                % Check material properties needed for analysis types
                if ((drv.type == drv.MECHANICAL || drv.type == drv.THERMO_MECHANICAL) &&...
                    (isempty(m.density) ||...
                     isempty(m.young)   ||...
                     isempty(m.poisson)))
                    fprintf(2,'Missing mechanical properties of material %s.',m.name);
                    status = 0; return;
                end
                if ((drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL) &&...
                        (isempty(m.density)  ||...
                         isempty(m.conduct)  ||...
                         isempty(m.hcapacity)))
                    fprintf(2,'Missing thermal properties of material %s.',m.name);
                    status = 0; return;
                end
                if (~isempty(m.young0) && isempty(m.young))
                    this.warnMsg('The value of the real Young modulus was provided, but not the simulation value. Therefore, these values will be assumed as equal.');
                    m.young = m.young0;
                end
                if (~isempty(m.young) && ~isempty(m.poisson))
                    shear_from_poisson = m.young / (2 + 2*m.poisson);
                    if (isempty(m.shear))
                        m.shear = shear_from_poisson;
                    elseif (m.shear ~= shear_from_poisson)
                        this.warnMsg('Provided shear modulus is not physically consistent with Young modulus and Poisson ratio.');
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = checkParticles(~,drv)
            status = 1;
            for i = 1:drv.n_particles
                p = drv.particles(i);
                if (isempty(p.material))
                    fprintf(2,'No material was provided to particle %d.',p.id);
                    status = 0; return;
                elseif (length(p.material) > 1)
                    fprintf(2,'More than one material was provided to particle %d.',p.id);
                    status = 0; return;
                end
            end
            
            % Check compatibility between different types of particles
            if (length(findobj(drv.particles,'type',drv.particles(1).SPHERE))   > 1 &&...
                length(findobj(drv.particles,'type',drv.particles(1).CYLINDER)) > 1)
                fprintf(2,'Interaction between SPEHERE and CYLINDER particles is not defined.');
                status = 0; return;
            end
        end
        
        %------------------------------------------------------------------
        function status = checkWalls(~,drv)
            status = 1;
            for i = 1:drv.n_walls
                w = drv.walls(i);
                if (w.type == w.LINE && isequal(w.coord_ini,w.coord_end))
                    fprintf(2,'Wall %d has no length.',w.id);
                    status = 0; return;
                end
                
                % Set wall as insulated if it has no material
                % (by default it is false)
                if (isempty(w.material))
                    w.insulated = true;
                end
            end
        end
        
        %------------------------------------------------------------------
        function status = checkModels(~,drv)
            status = 1;
            
            % Contact force normal
            if (~isempty(drv.search.b_interact.cforcen))
                if (drv.search.b_interact.cforcen.type == drv.search.b_interact.cforcen.VISCOELASTIC_LINEAR    ||...
                    drv.search.b_interact.cforcen.type == drv.search.b_interact.cforcen.VISCOELASTIC_NONLINEAR ||...
                    drv.search.b_interact.cforcen.type == drv.search.b_interact.cforcen.ELASTOPLASTIC_LINEAR)
                    if (length(findobj(drv.materials,'young',[])) > 1)
                        fprintf(2,'The selected normal contact force model requires the Young modulus of materials.');
                        status = 0; return;
                    end
                end
            end
            
            % Contact force tangent
            if (~isempty(drv.search.b_interact.cforcet))
                if (drv.search.b_interact.cforcet.type == drv.search.b_interact.cforcet.SPRING ||...
                    drv.search.b_interact.cforcet.type == drv.search.b_interact.cforcet.SPRING_SLIDER)
                    if (length(findobj(drv.materials,'poisson',[])) > 1)
                        fprintf(2,'The selected tangent contact force model requires the Poisson ratio of materials.');
                        status = 0; return;
                    end
                    
                elseif (drv.search.b_interact.cforcet.type == drv.search.b_interact.cforcet.SDS_LINEAR)
                    if (length(findobj(drv.materials,'poisson',[])) > 1)
                        fprintf(2,'The selected tangent contact force model requires the Poisson ratio of materials.');
                        status = 0; return;
                    end
                    if (drv.search.b_interact.cforcet.auto_damp && isempty(drv.search.b_interact.cforcet.restitution))
                        fprintf(2,'The selected tangent contact force model requires the tangent restitution coefficient.');
                        status = 0; return;
                    end
                    
                elseif (drv.search.b_interact.cforcet.type == drv.search.b_interact.cforcet.SDS_NONLINEAR)
                    if (drv.search.b_interact.cforcet.formula == drv.search.b_interact.cforcet.DD)
                        if (length(findobj(drv.materials,'shear',[])) > 1)
                            fprintf(2,'The selected tangent contact force model requires the Shear modulus of materials.');
                            status = 0; return;
                        end
                    elseif(drv.search.b_interact.cforcet.formula == drv.search.b_interact.cforcet.LTH)
                        if (length(findobj(drv.materials,'poisson',[])) > 1)
                            fprintf(2,'The selected tangent contact force model requires the Poisson ratio of materials.');
                            status = 0; return;
                        end
                    elseif(drv.search.b_interact.cforcet.formula == drv.search.b_interact.cforcet.ZZY)
                        if (length(findobj(drv.materials,'shear',[])) > 1)
                            fprintf(2,'The selected tangent contact force model requires the Shear modulus of materials.');
                            status = 0; return;
                        end
                        if (length(findobj(drv.materials,'poisson',[])) > 1)
                            fprintf(2,'The selected tangent contact force model requires the Poisson ratio of materials.');
                            status = 0; return;
                        end
                    elseif(drv.search.b_interact.cforcet.formula == drv.search.b_interact.cforcet.TTI)
                        if (length(findobj(drv.materials,'young',[])) > 1)
                            fprintf(2,'The selected normal contact force model requires the Young modulus of materials.');
                            status = 0; return;
                        end
                        if (length(findobj(drv.materials,'poisson',[])) > 1)
                            fprintf(2,'The selected tangent contact force model requires the Poisson ratio of materials.');
                            status = 0; return;
                        end
                    end
                end
            end
            
            % Rolling resistance
            if (~isempty(drv.search.b_interact.rollres))
                
            end
            
            % Area correction
            if (~isempty(drv.search.b_interact.corarea))
                if (length(findobj(drv.materials,'young0',[])) > 1)
                    fprintf(2,'Area correction models require the real value of the Young modulus to be provided.');
                    status = 0; return;
                end
            end         
            
            % Direct conduction
            if (~isempty(drv.search.b_interact.dconduc))
                
            end
            
            % Indirect conduction
            if (~isempty(drv.search.b_interact.iconduc))
                if (drv.type == drv.MECHANICAL)
                    drv.search.cutoff = 0;
                end
                if (isempty(drv.fluid_conduct))
                    this.warnMsg('Thermal conductivity of interstitial fluid was not specified, it will be assumed as zero.');
                end
                if (drv.search.b_interact.iconduc.type == drv.search.b_interact.iconduc.VORONOI_A)
                    if (drv.search.b_interact.iconduc.method == drv.search.b_interact.iconduc.VORONOI_DIAGRAM &&...
                        drv.n_particles < 3)
                        fprintf(2,'The selected indirect conduction model requires at least 3 particles to build the Voronoi diagram.');
                        status = 0; return;
                    end
                end
                if (drv.search.b_interact.iconduc.type == drv.search.b_interact.iconduc.VORONOI_B)
                    if (drv.search.b_interact.iconduc.method == drv.search.b_interact.iconduc.VORONOI_DIAGRAM &&...
                        drv.n_particles < 3)
                        fprintf(2,'The selected indirect conduction model requires at least 3 particles to build the Voronoi diagram.');
                        status = 0; return;
                    end
                end
                if (drv.search.b_interact.iconduc.type == drv.search.b_interact.iconduc.SURROUNDING_LAYER)
                    rmin = min([drv.particles.radius]);
                    if (drv.search.b_interact.iconduc.dist_min >= rmin)
                        fprintf(2,'The value of InteractionModel.indirect_conduction.min_distance is too high.');
                        status = 0; return;
                    end
                end
            end
        end
    end
    
    %% Static methods: auxiliary
    methods (Static)
        %------------------------------------------------------------------
        function warnMsg(msg)
            warning('off','backtrace');
            warning(msg);
            warning('on','backtrace');
        end
        
        %------------------------------------------------------------------
        function missingDataError(str)
            fprintf(2,'Missing data in project parameters file: %s\n',str);
        end
        
        %------------------------------------------------------------------
        function invalidParamError(str,msg)
            fprintf(2,'Invalid data in project parameters file: %s\n',str);
            if (~isempty(msg))
                fprintf(2,'%s.\n',msg);
            end
        end
        
        %------------------------------------------------------------------
        function invalidOptError(str,opt)
            fprintf(2,'Invalid data in project parameters file: %s\n',str);
            fprintf(2,'Available options: %s\n',opt);
        end
        
        %------------------------------------------------------------------
        function invalidModelError(msg)
            fprintf(2,'Invalid data in model parts file: %s\n',str);
            if (~isempty(msg))
                fprintf(2,'%s.\n',msg);
            end
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
                fprintf(2,'Error opening file of table values.\n');
                fprintf(2,'It must have the same path of the project parameters file.\n');
                status = 0; return;
            end
            vals = fscanf(fid,'%f',[col Inf])';
            fclose(fid);
            status = 1;
        end
    end
end