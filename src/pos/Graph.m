%% Graph class
%
%% Description
%
%% Implementation
%
classdef Graph < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        title string = string.empty;   % graph title
        
        % Axes data
        res_x uint8 = uint8.empty;   % flag for type of result in x axis
        res_y uint8 = uint8.empty;   % flag for type of result in y axis
        
        % Curves data
        n_curves uint8  = uint8.empty;    % number of curves in graph
        names    string = string.empty;   % vector of curves names
        px       uint8  = uint8.empty;    % vector of particles IDs for x axis result
        py       uint8  = uint8.empty;    % vector of particles IDs for y axis result
    end
    
    %% Constructor method
    methods
        function this = Graph()
            
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function execute(this,drv)
            
        end
    end
end