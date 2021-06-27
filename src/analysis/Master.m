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
        function runAnalysis(~)
            % Display header
            fprintf('==================================================================\n');
            fprintf('           DEMLab - Discrete Element Method Laboratory            \n');
            fprintf('                     Version 1.0 - July 2021                      \n');
            fprintf(' International Center for Numerical Methods in Engineering (CIMNE)\n');
            fprintf('==================================================================\n\n');
            
            % Get input file
            [file_name,file_path] = uigetfile('*.json','DEMLab - Input file','ProjectParameters');
            if (isequal(file_name,0))
                fprintf("No file selected.\n\n");
                fprintf("Exiting program...\n");
                return;
            end
            file_fullname = fullfile(file_path,file_name);
            fprintf('File selected:\n%s\n\n',file_fullname)
            
            % Open input file
            fid = fopen(file_fullname,'rt');
            if (fid < 0)
                fprintf(2,"Error opening input file.\n\n");
                fprintf("Exiting program...\n");
                return;
            end
            
            % Read input file
            fprintf('Reading input file...\n');
            [status,drv] = Read().execute(file_path,fid);
            if (~status)
                fprintf("Exiting program...\n");
                return;
            end
            
            % Execute analysis
            
        end
    end
end
