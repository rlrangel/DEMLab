%% Master class
%
%% Description
%
% This is the main class for running simulations and tests in DEMLab.
%
% It is responsible for managing the high-level tasks and call the
% appropriate methods to perform each stage of a simulation, from the
% reading of input files to the showing of results.
%
classdef Master < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        echo     uint8   = uint8.empty;     % echo level (amount of information to be printed in command window)
        tol      double  = double.empty;    % tolerance for testing against reference results
        path_in  string  = string.empty;    % path to input files folder
        files    string  = string.empty;    % full name of input files (with path)
        cur_file string  = string.empty;    % name of current file being run
        is_last  logical = logical.empty;   % flag for last input file to run
    end
    
    %% Constructor method
    methods
        function this = Master()
            this.setDefaultProps();
        end
    end
    
    %% Public methods: main functions
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.echo = 1;
            this.tol  = 1e-12;
        end
        
        %------------------------------------------------------------------
        function runSimulations(this,echo)
            if (nargin > 1)
                this.echo = echo;
            end
            
            % Print header
            this.printHeader();
            
            % Get input files
            if (~this.getInputFiles())
                return;
            end
            
            % Display input files
            this.displayInputFiles();
            
            % Run each input file
            for i = 1:length(this.files)
                this.is_last = (i == length(this.files));
                
                % Clear driver
                clearvars drv;
                
                % Get current file name and extension
                this.cur_file = this.files(i);
                [~,~,ext] = fileparts(this.cur_file);
                
                % Run according to file extension
                if (strcmp(ext,'.json'))
                    [status,drv] = this.runAnalysis();
                    if (~status)
                        continue;
                    end
                elseif (strcmp(ext,'.mat'))
                    [status,drv] = this.loadResults();
                    if (~status)
                        continue;
                    end
                else
                    fprintf('Input file:\n%s\n',this.cur_file);
                    fprintf(2,'\nInvalid input file extension.\n');
                    this.printExit();
                    continue;
                end
                
                % Pos-process
                drv.posProcess();
                
                % Finish current analysis
                fprintf('\nFinished!\n');
                if (~this.is_last)
                    fprintf('\n------------------------------------------------------------------\n\n');
                end
            end
        end
        
        %------------------------------------------------------------------
        function [status,drv] = runAnalysis(this)
            % Open parameters file
            fprintf('Parameters file:\n%s\n',this.cur_file);
            fid = fopen(this.cur_file,'rt');
            if (fid < 0)
                fprintf(2,'\nError opening parameters file.\n');
                this.printExit();
                status = 0;
                return;
            end
            
            % Read parameters file
            if (this.echo > 0)
                fprintf('\nReading parameters file...\n');
            end
            read = Read();
            [status,drv,storage_file] = read.execute(this.path_in,fid);
            
            % Pre analysis tasks
            if (status == 0)
                this.printExit();
                return;
                
            elseif (status == 1) % start analysis from the beggining
                % Check input data
                if (this.echo > 0)
                    fprintf('\nChecking consistency of input data...\n');
                end
                if (~read.check(drv))
                    this.printExit();
                    status = 0;
                    return;
                end
                
                % Pre-process
                if (this.echo > 0)
                    fprintf('\nPre-processing...\n');
                end
                if (~drv.preProcess())
                    this.printExit();
                    status = 0;
                    return;
                end
                
                % Print simulation information
                if (this.echo > 0)
                    this.printSimulationInfo(drv);
                    fprintf('\nStarting analysis:\n');
                    fprintf('%s\n',datestr(now));
                end
                
            elseif (status == 2) % continue analysis from previous state
                f = dir(storage_file);
                fprintf('\nStorage file found (%.3f Mb):\n%s\n',f.bytes/10e5,storage_file);
                
                % Load storage file
                [loaded,drv] = this.loadStorageFile(storage_file);
                if (~loaded)
                    status = 0;
                    return;
                end
                
                % Set output folder to current folder
                drv.path_out = this.path_in;
                
                % Update starting elapsed time
                drv.start_time = drv.total_time;
                
                % Print simulation information
                if (this.echo > 0)
                    this.printSimulationInfo(drv);
                    fprintf('\nStarting analysis from previous results:\n');
                    fprintf('%s\n',datestr(now));
                end
            end
            
            % Show starting configuration
            if (this.echo > 0)
                Animation().curConfig(drv,'Starting');
            end
            
            % Execute analysis
            tic;
            drv.process();
            
            % Print finished status
            if (this.echo > 0)
                this.printFinishedStatus(drv,status);
            end
        end
        
        %------------------------------------------------------------------
        function [status,drv] = loadResults(this)
            status = 1;
            f = dir(this.cur_file);
            fprintf('Storage file (%.3f Mb):\n%s\n',f.bytes/10e5,this.cur_file);
            
            % Load storage file
            [loaded,drv] = this.loadStorageFile(this.cur_file);
            if (~loaded)
                status = 0;
                return;
            end
            
            % Set output folder to current folder
            drv.path_out = this.path_in;
            
            % Show current configuration
            if (this.echo > 0)
                Animation().curConfig(drv,'');
            end
        end
        
        %------------------------------------------------------------------
        function runTests(this,echo,tol)
            this.compareTest(drv);
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
            fprintf('      Polytechnic University of Catalonia (UPC BarcelonaTech)     \n');
            fprintf('==================================================================\n\n');
        end
        
        %------------------------------------------------------------------
        function status = getInputFiles(this)
            status  = 1;
            
            % Get files from dialog
            filter  = {'*.json','Parameters File (*.json)';'*.mat','Storage File (*.mat)'};
            title   = 'DEMLab - Input file';
            default = 'ProjectParameters.json';
            [file_names,path] = uigetfile(filter,title,default,'MultiSelect','on');
            if (isequal(file_names,0))
                fprintf('No file selected.\n');
                fprintf('\nExiting program...\n');
                status = 0;
                return;
            end
            file_fullnames = fullfile(path,file_names);
            
            % Convert to string array
            this.files   = string(file_fullnames);
            this.path_in = string(path);
        end
        
        %------------------------------------------------------------------
        function displayInputFiles(this)
            n_files = length(this.files);
            fprintf('%d input files selected:\n',n_files);
            for i = 1:n_files
                fprintf('%s\n',this.files(i));
            end
            fprintf('\n------------------------------------------------------------------\n\n');
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
        function printExit(this)
            if (this.is_last)
                fprintf('\nExiting program...\n');
            else
                fprintf('\nAborted!\n');
                fprintf('\n------------------------------------------------------------------\n\n');
            end
        end
        
        %------------------------------------------------------------------
        function [status,drv] = loadStorageFile(this,storage_file)
            status = 1;
            try
                warning off MATLAB:load:variableNotFound
                load(storage_file,'drv');
                warning on MATLAB:load:variableNotFound
            catch
                fprintf(2,'\nError loading storage file.\n');
                this.printExit();
                status = 0;
                return;
            end
            if (~exist('drv','var') || isempty(drv))
                fprintf(2,'\nInvalid stored data.\n');
                this.printExit();
                status = 0;
                return;
            end
        end
        
        %------------------------------------------------------------------
        function compareTest(~,drv)
            name_1 = strcat(drv.path_out,"reference_results.pos");
            name_2 = strcat(drv.path_out,drv.name,".pos");
            
            if (exist(name_1,'file') ~= 2)
                fprintf(2,'\nMissing reference results file!\n');
                if (exist(name_2,'file') == 2)
                    warning off MATLAB:DELETE:FileNotFound
                    delete(sprintf('%s',name_2));
                    warning on MATLAB:DELETE:FileNotFound
                end
                return;
            end
            
            file_1 = javaObject('java.io.File',name_1);
            file_2 = javaObject('java.io.File',name_2);
            
            is_equal = javaMethod('contentEquals','org.apache.commons.io.FileUtils',file_1,file_2);
            
            if (is_equal)
                fprintf(1,'\nTest passed!\n');
            else
                fprintf(2,'\nResults are different!\n');
            end
            if (exist(name_2,'file') == 2)
                warning off MATLAB:DELETE:FileNotFound
                delete(sprintf('%s',name_2));
                warning on MATLAB:DELETE:FileNotFound
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