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
            
            % Get input file name, path and extension
            if (isempty(file_fullname))
                filter  = {'*.json','Parameters File (*.json)';'*.mat','Results File (*.mat)'};
                title   = 'DEMLab - Input file';
                default = 'ProjectParameters.json';
                [file_name,file_path] = uigetfile(filter,title,default);
                if (isequal(file_name,0))
                    fprintf('No file selected.\n');
                    fprintf('\nExiting program...\n');
                    return;
                end
                file_fullname = fullfile(file_path,file_name);
                [~,~,ext] = fileparts(file_fullname);
            else
                [file_path,~,ext] = fileparts(file_fullname);
            end
            
            % Run according to input file type
            if (strcmp(ext,'.json'))
                % Open parameters file
                fprintf('Parameters file selected:\n%s\n',file_fullname)
                fid = fopen(file_fullname,'rt');
                if (fid < 0)
                    fprintf(2,'\nError opening parameters file.\n');
                    fprintf('\nExiting program...\n');
                    return;
                end

                % Read parameters file
                read = Read();
                fprintf('\nReading parameters file...\n');
                [status,drv,storage] = read.execute(file_path,fid);

                % Pre analysis tasks
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
                    % Load results file
                    fprintf('\nResults file found:\n%s\n',storage)
                    load(storage,'drv');
                    if (~exist('drv','var'))
                        fprintf(2,'n\Invalid results file.\n');
                        fprintf('\nExiting program...\n');
                    end
                    
                    % Update starting elapsed time
                    drv.start_time = drv.total_time;

                    % Print simulation information
                    this.printSimulationInfo(drv);
                    fprintf('\nStarting analysis from previous results:\n');
                    fprintf('%s\n',datestr(now));
                end

                % Show starting configuration
                Animation().curConfig(drv,'Starting');
                
                % Execute analysis
                tic;
                drv.process();

                % Print finished status
                this.printFinishedStatus(drv,status);
                
            elseif (strcmp(ext,'.mat'))
                % Load results file
                fprintf('Results file selected:\n%s\n',file_fullname);
                load(file_fullname,'drv');
                if (~exist('drv','var'))
                    fprintf(2,'n\Invalid results file.\n');
                    fprintf('\nExiting program...\n');
                end
                
                % Show current configuration
                Animation().curConfig(drv,'');
            else
                fprintf(2,'n\Invalid input file.\n');
                fprintf('\nExiting program...\n');
                return;
            end
            
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
            switch drv.type
                case drv.MECHANICAL
                    fprintf('Type.................: Mechanical\n');
                case drv.type == drv.THERMAL
                    fprintf('Type.................: Thermal\n');
                case drv.THERMO_MECHANICAL
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