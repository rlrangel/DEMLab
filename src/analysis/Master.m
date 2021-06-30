%% Master class
%
%% Description
%
%% Implementation
%
classdef Master < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Master()
            
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function runSimulation(this)
            % Print header
            this.printHeader();
            
            % Get input file
            [file_name,file_path] = uigetfile('*.json','DEMLab - Input file','ProjectParameters');
            file_fullname = fullfile(file_path,file_name);
            if (isequal(file_name,0))
                fprintf("No file selected.\n");
                fprintf("\nExiting program...\n");
                return;
            end
            fprintf('File selected:\n%s\n\n',file_fullname)
            
            % Open input file
            fid = fopen(file_fullname,'rt');
            if (fid < 0)
                fprintf(2,"Error opening input file.\n");
                fprintf("\nExiting program...\n");
                return;
            end
            
            % Read input file
            read = Read();
            fprintf('Reading input file...\n');
            [status,drv] = read.execute(file_path,fid);
            if (~status)
                fprintf("\nExiting program...\n");
                return;
            end
            
            % Check input data
            fprintf('\nChecking consistency of input data...\n');
            status = read.check(drv);
            if (~status)
                fprintf("\nExiting program...\n");
                return;
            end
            
            % Start parallelization
            this.startParallel(drv);
            
            % Pre-processs
            fprintf('\nPre-processing...\n');
            if (~drv.preProcess())
                fprintf("\nExiting program...\n");
                return;
            end
            
            % Print simulation information
            this.printSimulationInfo(drv);
            
            % Execute analysis
            fprintf('\nStarting analysis:\n');
            fprintf('%s\n',datestr(now));
            tic;
            drv.runAnalysis();
            
            % Print finished status
            t = seconds(toc);
            t.Format = 'hh:mm:ss.SS';
            fprintf('\nAnalysis finished:\n');
            fprintf('%s\n',datestr(now));
            fprintf('Total time: %s\n',string(t));
        end
        
        %------------------------------------------------------------------
        function printHeader(~)
            fprintf('==================================================================\n');
            fprintf('           DEMLab - Discrete Element Method Laboratory            \n');
            fprintf('                     Version 1.0 - July 2021                      \n');
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
        function startParallel(~,drv)
            p = gcp('nocreate');
            if (drv.parallel)
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
