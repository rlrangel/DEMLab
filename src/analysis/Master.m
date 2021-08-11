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
            [status,drv] = read.execute(file_path,fid);
            if (~status)
                fprintf('\nExiting program...\n');
                return;
            end
            
            % Check input data
            fprintf('\nChecking consistency of input data...\n');
            status = read.check(drv);
            if (~status)
                fprintf('\nExiting program...\n');
                return;
            end
            
            % Start parallelization (currently not available)
            %this.startParallel(drv);
            
            % Pre-process
            fprintf('\nPre-processing...\n');
            if (~drv.preProcess())
                fprintf('\nExiting program...\n');
                return;
            end
            
            % Show initial configuration
            this.drawInitConfig(drv);
            
            % Print simulation information
            this.printSimulationInfo(drv);
            
            % Execute analysis
            fprintf('\nStarting analysis:\n');
            fprintf('%s\n',datestr(now));
            tic;
            drv.process();
            
            % Print finished status
            this.printFinishedStatus();
            
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
            fprintf('Time step............: %f\n',drv.time_step);
            if (~isempty(drv.max_time))
                fprintf('Final time...........: %f\n',drv.max_time);
            end
            if (~isempty(drv.max_step))     
                fprintf('Maximum steps........: %d\n',drv.max_step);
            end
        end
        
        %------------------------------------------------------------------
        function printFinishedStatus(~)
            t = seconds(toc);
            t.Format = 'hh:mm:ss.SS';
            fprintf('\n\nAnalysis finished:\n');
            fprintf('%s\n',datestr(now));
            fprintf('Total time: %s\n',string(t));
        end
        
        %------------------------------------------------------------------
        function drawInitConfig(~,drv)
            % Create figure
            fig = figure('Name','Initial Configuration');
            fig.Units = 'normalized';
            fig.Position = [0.1 0.1 0.8 0.8];
            axis(gca,'equal');
            hold on;
            
            % Create and set animation object (use it to support drawing)
            anim          = Animation();
            anim.coord_x  = drv.result.coord_x(:,1);
            anim.coord_y  = drv.result.coord_y(:,1);
            anim.radius   = drv.result.radius(:,1);
            anim.wall_pos = drv.result.wall_position(:,1);
            
            % Show initial temperature for thermal analysis
            if (drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL)
                title(gca,'Initial Temperature');
                anim.res_part = drv.result.temperature(:,1);
                anim.res_wall = drv.result.wall_temperature(:,1);
                
                % Set color scale
                [min_val,max_val] = anim.scalarValueLimits();
                anim.res_range = linspace(min_val,max_val,256);
                colormap jet;
                caxis([min_val,max_val]);
                colorbar;
            else
                title(gca,'Initial Positions');
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
