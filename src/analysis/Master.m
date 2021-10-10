%% Master class
%
%% Description
%
% This is the main class for running simulations in DEMLab.
%
% It is responsible for managing the high-level tasks and call the
% appropriate methods to perform each stage of a simulation, from the
% reading of input files to the showing of results.
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
        function execute(this,file_fullnames,echo,test)
            % Check input arguments
            if (nargin < 2)
                fprintf('No file selected.\n');
                fprintf('\nExiting program...\n');
                return;
            elseif (nargin < 3)
                echo = 1;
                test = false;
            elseif (nargin < 4)
                test = false;
            end
            
            % Print header
            this.printHeader();
            
            % Get input files
            if (isempty(file_fullnames) || (length(file_fullnames) == 1 && file_fullnames == ""))
                % Open selection dialog
                filter  = {'*.json','Parameters File (*.json)';'*.mat','Storage File (*.mat)'};
                title   = 'DEMLab - Input file';
                default = 'ProjectParameters.json';
                [file_names,path_in] = uigetfile(filter,title,default,'MultiSelect','on');
                if (isequal(file_names,0))
                    fprintf('No file selected.\n');
                    fprintf('\nExiting program...\n');
                    return;
                end
                file_fullnames = fullfile(path_in,file_names);
                
                % Convert to string array
                file_fullnames = string(file_fullnames);
                path_in        = string(path_in);
            else
                % Convert to string array
                file_fullnames = string(file_fullnames);
                
                % Eliminate empty strings
                file_fullnames = file_fullnames(file_fullnames~="");
                
                % Check for non empty files
                if (isempty(file_fullnames))
                    fprintf('No file selected.\n');
                    fprintf('\nExiting program...\n');
                    return;
                end
                
                % Get path of input files
                path_in = strcat(fileparts(file_fullnames(1)),'\');
            end
            
            % Display input files
            n_files = length(file_fullnames);
            if (n_files > 1 && echo > 0)
                fprintf('%d input files selected:\n',n_files);
                for i = 1:n_files
                    fprintf('%s\n',file_fullnames(i));
                end
                fprintf('\n------------------------------------------------------------------\n\n');
            end
            
            % Run each input file
            for i = 1:n_files
                is_last = (i == n_files);
                
                % Check extension
                cur_file = file_fullnames(i);
                [~,~,ext] = fileparts(cur_file);
                
                % Clear driver
                clearvars drv;
                
                % Run according to input file type
                if (strcmp(ext,'.json'))
                    % Open parameters file
                    fprintf('Parameters file:\n%s\n',cur_file);
                    fid = fopen(cur_file,'rt');
                    if (fid < 0)
                        fprintf(2,'\nError opening parameters file.\n');
                        this.printExit(is_last);
                        continue;
                    end
                    
                    % Read parameters file
                    if (echo > 0)
                        fprintf('\nReading parameters file...\n');
                    end
                    read = Read();
                    [status,drv,storage] = read.execute(path_in,fid);
                    
                    % Pre analysis tasks
                    if (status == 0)
                        this.printExit(is_last);
                        continue;
                        
                    elseif (status == 1) % start analysis from the beggining
                        % Check input data
                        if (echo > 0)
                            fprintf('\nChecking consistency of input data...\n');
                        end
                        status = read.check(drv);
                        if (~status)
                            this.printExit(is_last);
                            continue;
                        end
                        
                        % Pre-process
                        if (echo > 0)
                            fprintf('\nPre-processing...\n');
                        end
                        if (~drv.preProcess())
                            this.printExit(is_last);
                            continue;
                        end
                        
                        % Print simulation information
                        if (echo > 0)
                            this.printSimulationInfo(drv);
                            fprintf('\nStarting analysis:\n');
                            fprintf('%s\n',datestr(now));
                        end
                        
                    elseif (status == 2) % continue analysis from previous state
                        f = dir(storage);
                        fprintf('\nStorage file found (%.3f Mb):\n%s\n',f.bytes/10e5,storage);
                        
                        % Load storage file
                        try
                            warning off MATLAB:load:variableNotFound
                            load(storage,'drv');
                            warning on MATLAB:load:variableNotFound
                        catch
                            fprintf(2,'\nError loading storage file.\n');
                            this.printExit(is_last);
                            continue;
                        end
                        if (~exist('drv','var') || isempty(drv))
                            fprintf(2,'\nInvalid stored data.\n');
                            this.printExit(is_last);
                            continue;
                        end
                        
                        % Update starting elapsed time
                        drv.start_time = drv.total_time;

                        % Print simulation information
                        if (echo > 0)
                            this.printSimulationInfo(drv);
                            fprintf('\nStarting analysis from previous results:\n');
                            fprintf('%s\n',datestr(now));
                        end
                    end
                    
                    % Show starting configuration
                    if (echo > 0)
                        Animation().curConfig(drv,'Starting');
                    end
                    
                    % Execute analysis
                    tic;
                    drv.process();
                    
                    % Print finished status
                    if (echo > 0)
                        this.printFinishedStatus(drv,status);
                    end
                    
                elseif (strcmp(ext,'.mat'))
                    f = dir(cur_file);
                    fprintf('Storage file (%.3f Mb):\n%s\n',f.bytes/10e5,cur_file);
                    
                    % Load storage file
                    try
                        warning off MATLAB:load:variableNotFound
                        load(cur_file,'drv');
                        warning on MATLAB:load:variableNotFound
                    catch
                        fprintf(2,'\nError loading storage file.\n');
                        this.printExit(is_last);
                        continue;
                    end
                    if (~exist('drv','var') || isempty(drv))
                        fprintf(2,'\nInvalid stored data.\n');
                        this.printExit(is_last);
                        continue;
                    end
                    
                    % Show current configuration
                    if (echo > 0)
                        Animation().curConfig(drv,'');
                    end
                else
                    fprintf(2,'\nInvalid input file extension.\n');
                    this.printExit(is_last);
                    continue;
                end
                
                % Pos-process
                drv.posProcess();
                
                % Finish current analysis
                if (test)
                    this.compareTest(drv);
                else
                    fprintf('\nFinished!\n');
                end
                if (~is_last)
                    fprintf('\n------------------------------------------------------------------\n\n');
                end
            end
        end
    end
    
    %% Public methods: auxiliary functions
    methods
        %------------------------------------------------------------------
        function printHeader(~)
            fprintf('==================================================================\n');
            fprintf('           DEMLab - Discrete Element Method Laboratory            \n');
            fprintf('                  Version 1.0 - September 2021                    \n');
            fprintf(' International Center for Numerical Methods in Engineering (CIMNE)\n');
            fprintf('==================================================================\n\n');
        end
        
        %------------------------------------------------------------------
        function printSimulationInfo(~,drv)
            fprintf('\nSimulation ready:\n');
            if (~isempty(drv.name))
                fprintf('Name...................: %s\n',drv.name);
            end
            switch drv.type
                case drv.MECHANICAL
                    fprintf('Type...................: Mechanical\n');
                case drv.type == drv.THERMAL
                    fprintf('Type...................: Thermal\n');
                case drv.THERMO_MECHANICAL
                    fprintf('Type...................: Thermo-mechanical\n');
            end
            if (~isempty(drv.n_walls))
                fprintf('Number of walls........: %d\n',drv.n_walls);
            end
            if (~isempty(drv.n_particles))
                fprintf('Number of particles....: %d\n',drv.n_particles);
            end
            if (~isempty(drv.particles))
                ravg = mean([drv.particles.radius]);
                rdev = std([drv.particles.radius]);
                rmin = min([drv.particles.radius]);
                rmax = max([drv.particles.radius]);
                if (rdev/rmin < 1e-8)
                    rdev = 0;
                end
                fprintf('Average radius.........: %.3e\n',ravg);
                fprintf('Radius deviation.......: %.3e\n',rdev);
                if (rdev ~= 0)
                    fprintf('Min radius.............: %.3e\n',rmin);
                    fprintf('Max radius.............: %.3e\n',rmax);
                end
            end
            if (~isempty(drv.particles) &&...
               (drv.type == drv.THERMAL || drv.type == drv.THERMO_MECHANICAL))
                tavg = mean([drv.particles.temperature]);
                tdev = std([drv.particles.temperature]);
                tmin = min([drv.particles.temperature]);
                tmax = max([drv.particles.temperature]);
                fprintf('Average temperature....: %.3e\n',tavg);
                fprintf('Temperature deviation..: %.3e\n',tdev);
                if (tdev ~= 0)
                    fprintf('Min temperature........: %.3e\n',tmin);
                    fprintf('Max temperature........: %.3e\n',tmax);
                end
            end
            if (~isempty(drv.mass_particle))
                fprintf('Total mass.............: %.3e\n',drv.mass_particle);
            end
            if (~isempty(drv.time_step))
                fprintf('Time step..............: %.3e\n',drv.time_step);
            end
            if (~isempty(drv.max_time))
                fprintf('Final time.............: %f\n',drv.max_time);
            end
        end
        
        %------------------------------------------------------------------
        function printFinishedStatus(~,drv,status)
            fprintf('\n\nAnalysis finished:\n');
            fprintf('%s\n',datestr(now));
            if (status == 1)
                time            = seconds(toc);
                avg_time        = time/drv.step;
                time.Format     = 'hh:mm:ss.SS';
                avg_time.Format = 's';
                fprintf('Total time:.....: %s\n',string(time));
                fprintf('Avg step time:..: %s\n',string(avg_time));
            elseif (status == 2)
                curr_time         = seconds(toc);
                total_time        = seconds(drv.total_time);
                avg_time          = total_time/drv.step;
                curr_time.Format  = 'hh:mm:ss.SS';
                total_time.Format = 'hh:mm:ss.SS';
                avg_time.Format   = 's';
                fprintf('Current analysis time:..: %s\n',string(curr_time));
                fprintf('Total simulation time:..: %s\n',string(total_time));
                fprintf('Avg step time:..........: %s\n',string(avg_time));
            end
        end
        
        %------------------------------------------------------------------
        function printExit(~,is_last)
            if (is_last)
                fprintf('\nExiting program...\n');
            else
                fprintf('\nAborted!\n');
                fprintf('\n------------------------------------------------------------------\n\n');
            end
        end
        
        %------------------------------------------------------------------
        function compareTest(~,drv)
%             name_1 = strcat(drv.path_out,"base_results.pos");
%             name_2 = strcat(drv.path_out,drv.name,"mech_bounce_10001.pos");
%             
%             file_1 = javaObject('java.io.File',name_1);
%             file_2 = javaObject('java.io.File',name_2);
% 
%             is_equal = javaMethod('contentEquals','org.apache.commons.io.FileUtils',file_1,file_2);
%             
%             if (is_equal)
%                 fprintf('\nTest passed!\n');
%             else
%                 fprintf('\nResults are different!\n');
%             end
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