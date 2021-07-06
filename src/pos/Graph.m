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
        gtitle string = string.empty;   % graph title
        path   string = string.empty;   % path to model folder
        
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
            % Create a new window
            fig = figure;
            
            % Set properties
            grid on;
            hold on;
            movegui(fig,'center');
            title(this.gtitle);
            
            % Plot curves
            leg = strings(this.n_curves,1);
            for i = 1:this.n_curves
                name = this.names(i);
                
                % Get X,Y data arrays
                x = this.getData(drv,this.res_x,this.px);
                y = this.getData(drv,this.res_y,this.py);
                
                % Remove NaN (Not a Number) and adjust array sizes
                nanx = find(isnan(x),1);
                nany = find(isnan(y),1);
                idx  = length(x);
                if (~isempty(nanx))
                    idx = min(idx,nanx-1);
                end
                if (~isempty(nany))
                    idx = min(idx,nany-1);
                end
                if (idx == 0)
                    warning('off','backtrace');
                    warning('Curve %s of graph %s has no valid results and was not ploted.',name,this.gtitle);
                    warning('on','backtrace');
                    continue;
                end
                x = x(1:idx);
                y = y(1:idx);
                
                % Plot curve
                plot(x,y);
                leg(i) = name;
            end
            
            % Set legend
            legend(leg);
            
            % Save picture
            file_name = strcat(this.path,'\',this.gtitle,'.png');
            saveas(gcf,file_name);
        end
        
        %------------------------------------------------------------------
        function X = getData(~,drv,res,p)
            switch res
                case drv.result.TIME
                    X = drv.result.times;
                case drv.result.STEP
                    X = drv.result.steps;
                case drv.result.RADIUS
                    X = drv.result.radius(p,:);
                case drv.result.FORCE_MOD
                    X = drv.result.force_mod(p,:);
                case drv.result.FORCE_X
                    X = drv.result.force_x(p,:);
                case drv.result.FORCE_Y
                    X = drv.result.force_y(p,:);
                case drv.result.TORQUE
                    X = drv.result.torque(p,:);
                case drv.result.COORDINATE_X
                    X = drv.result.coord_x(p,:);
                case drv.result.COORDINATE_Y
                    X = drv.result.coord_y(p,:);
                case drv.result.ORIENTATION
                    X = drv.result.orientation(p,:);
                case drv.result.VELOCITY_MOD
                    X = drv.result.velocity_mod(p,:);
                case drv.result.VELOCITY_X
                    X = drv.result.velocity_x(p,:);
                case drv.result.VELOCITY_Y
                    X = drv.result.velocity_y(p,:);
                case drv.result.VELOCITY_ROT
                    X = drv.result.velocity_rot(p,:);
                case drv.result.ACCELERATION_MOD
                    X = drv.result.acceleration_mod(p,:);
                case drv.result.ACCELERATION_X
                    X = drv.result.acceleration_x(p,:);
                case drv.result.ACCELERATION_Y
                    X = drv.result.acceleration_y(p,:);
                case drv.result.ACCELERATION_ROT
                    X = drv.result.acceleration_rot(p,:);
                case drv.result.TEMPERATURE
                    X = drv.result.temperature(p,:);
                case drv.result.HEAT_RATE
                    X = drv.result.heat_rate(p,:);
            end
        end
    end
end