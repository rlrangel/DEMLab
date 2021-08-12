%% Master class
%
%% Description
%
% This is the main class for running a DEMLab simulation.
%
% The _execute_ method is responsible for managing the high-level tasks
% and call the appropriate methods to perform each task, from the reading
% of the input files to the showing of the results.
%
classdef Master
    %% Constructor method
    methods
        function this = Master()
            
        end
    end
    
    %% Public methods: main function
    methods
        %------------------------------------------------------------------
        function execute(this,file_fullname)
            % Print header
            this.printHeader();
            
            % Get input file name and path
            if (isempty(file_fullname))
                [file_name,file_path] = uigetfile('*.json','DEMLab - Input file','ProjectParameters');
                file_fullname = fullfile(file_path,file_name);
                if (isequal(file_name,0))
                    fprintf('No file selected.\n');
                    fprintf('\nExiting program...\n');
                    return;
                end
            else
                file_path = fileparts(file_fullname);
            end
            fprintf('File selected:\n%s\n',file_fullname)
            
            % Open input file
            fid = fopen(file_fullname,'rt');
            if (fid < 0)
                fprintf(2,'\nError opening input file.\n');
                fprintf('\nExiting program...\n');
                return;
            end
            
            % Read input file
            read = Read();
            fprintf('\nReading input file...\n');
            [status,drv,storage] = read.execute(file_path,fid);
            
            % 
            if (status == 0)
                fprintf('\nExiting program...\n');
                return;
                
            elseif (status == 1) % start analysis from beggining
                % Check input data
                fprintf('\nChecking consistency of input data...\n');
                status = read.check(drv);
                if (~status)
                    fprintf('\nExiting program...\n');
                    return;
                end
                
                % Pre-process
                fprintf('\nPre-processing...\n');
                if (~drv.preProcess())
                    fprintf('\nExiting program...\n');
                    return;
                end
                
                % Print simulation information
                this.printSimulationInfo(drv);
                fprintf('\nStarting analysis:\n');
                fprintf('%s\n',datestr(now));
                
            elseif (status == 2) % continue analysis from previous state
                % Load stored results
                fprintf('\nStored results were found in file:\n%s\n',storage)
                load(storage,'drv');
                
                % Update starting elapsed time
                drv.start_time = drv.total_time;
                
                % Print simulation information
                this.printSimulationInfo(drv);
                fprintf('\nStarting analysis from previous results:\n');
                fprintf('%s\n',datestr(now));
            end
            
            % Show initial or current configuration
            this.drawCurConfig(drv);
            
            % Execute analysis
            tic;
            drv.process();
            
            % Print finished status
            this.printFinishedStatus(drv,status);
            
            % Pos-process
            drv.posProcess()
            fprintf('\nFinished!\n\n');
        end
    end
    
    %% Public methods: auxiliary functions
    methods
        %------------------------------------------------------------------
        function printHeader(~)
            fprintf('==================================================================\n');
            fprintf('           DEMLab - Discrete Element Method Laboratory            \n');
            fprintf('                    Version 1.0 - August 2021                     \n');
            fprintf(' International Center for Numerical Methods in Engineering (CIMNE)\n');
            fprintf('==================================================================\n\n');
        end
        
        %------------------------------------------------------------------
        function printSimulationInfo(~,drv)
            fprintf('\nSimulation ready:\n');
            fprintf('Name.................: %s\n',drv.name);
            if (drv.type == drv.MECHANICAL)
                fprintf('Type.................: Mechanical\n');
            elseif (drv.type == drv.THERMAL)
                fprintf('Type.................: Thermal\n');
            elseif (drv.type == drv.THERMO_MECHANICAL)
                fprintf('Type.................: Thermo-mechanical\n');
            end
            fprintf('Number of particles..: %d\n',drv.n_particles);
            fprintf('Number of walls......: %d\n',drv.n_walls);
            fprintf('Time step............: %f\n',drv.time_step);
            if (~isempty(drv.max_time))
                fprintf('Final time...........: %f\n',drv.max_time);
            end
            if (~isempty(drv.max_step))     
                fprintf('Maximum steps........: %d\n',drv.max_step);
            end
        end
        
        %------------------------------------------------------------------
        function printFinishedStatus(~,drv,status)
            fprintf('\n\nAnalysis finished:\n');
            fprintf('%s\n',datestr(now));
            if (status == 1)
                time = seconds(toc);
                time.Format = 'hh:mm:ss.SS';
                fprintf('Total time: %s\n',string(time));
            elseif (status == 2)
                curr_time  = seconds(toc);
                total_time = seconds(drv.total_time);
                curr_time.Format  = 'hh:mm:ss.SS';
                total_time.Format = 'hh:mm:ss.SS';
                fprintf('Current analysis time: %s\n',string(curr_time));
                fprintf('Total simulation time: %s\n',string(total_time));
            end
        end
        
        %------------------------------------------------------------------
        function drawCurConfig(~,drv)
            % Create figure
            fig = figure;
            fig.Units = 'normalized';
            fig.Position = [0.1 0.1 0.8 0.8];
            axis(gca,'equal');
            hold on;
            
            % Create and set animation object (use it to support drawing)
            anim = Animation();
            
            % Get last stored results
            col = drv.result.idx;
            anim.coord_x  = drv.result.coord_x(:,col);
            anim.coord_y  = drv.result.coord_y(:,col);
            anim.radius   = drv.result.radius(:,col);
            anim.wall_pos = drv.result.wall_position(:,col);
            
            % Show initial temperature for thermal analysis
            if (drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL)
                title(gca,sprintf('Temperature - Time: %.3f',drv.time));                
                anim.res_part = drv.result.temperature(:,col);
                anim.res_wall = drv.result.wall_temperature(:,col);
                
                % Set color scale
                [min_val,max_val] = anim.scalarValueLimits();
                anim.res_range = linspace(min_val,max_val,256);
                colormap jet;
                caxis([min_val,max_val]);
                colorbar;
            else
                title(gca,sprintf('Positions - Time: %.3f',drv.time)); 
            end
            
            % Draw model components
            for i = 1:drv.n_particles
                if (drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL)
                    anim.drawParticleScalar(i,1);
                else
                    anim.drawParticleMotion(i,1);
                end
            end
            for i = 1:drv.n_walls
                anim.drawWall(drv.walls(i),1);
            end
            if (~isempty(drv.bbox))
                if (drv.bbox.isActive(drv.time))
                    anim.drawBBox(drv.bbox);
                end
            end
            for i = 1:length(drv.sink)
                if (drv.sink(i).isActive(drv.time))
                    anim.drawSink(drv.sink(i));
                end
            end
            
            % Adjust figure bounding box
            xmin = min(xlim);
            xmax = max(xlim);
            xlim([xmin-(xmax-xmin)/10,xmax+(xmax-xmin)/10]);
            pause(3);
        end
        
        %------------------------------------------------------------------
        % To be called before the analysis (currently not available)
        function startParallel(~,drv)
            p = gcp('nocreate');
            if (drv.parallel)
                max_workers = parcluster('local').NumWorkers;
                if (drv.workers > max_workers)
                    drv.workers = max_workers;
                    warning('off','backtrace');
                    warning('The selected number of workers is greater than the available number of workers in this machine. The simulation will proceed with the %d available workers',max_workers);
                    warning('on','backtrace');
                end
                if (isempty(p))
                    fprintf('\n');
                    parpool(drv.workers);
                elseif (p.NumWorkers ~= drv.workers)
                    fprintf('\n');
                    delete(p)
                    parpool(drv.workers);
                end
            elseif (~isempty(p))
                fprintf('\n');
                delete(p);
            end
            ps = parallel.Settings;
            ps.Pool.AutoCreate = false;
        end
    end
end
