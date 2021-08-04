%% Master class
%
%% Description
%
% This is the main class for running the simulation.
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
    
    %% Public methods
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
            
            % Pre-process
            fprintf('\nPre-processing...\n');
            if (~drv.preProcess())
                fprintf('\nExiting program...\n');
                return;
            end
            
            % Print simulation information
            this.printSimulationInfo(drv);
            
            % Start parallelization
            this.startParallel(drv);
            
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
