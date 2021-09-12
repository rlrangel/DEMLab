%% Graph class
%
%% Description
%
% This is a handle class responsible for creating, displaying and saving
% a graph of a required result.
%
classdef Graph < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        gtitle string = string.empty;   % graph title
        
        % Axes data
        res_x uint8 = uint8.empty;   % flag for type of result in x axis
        res_y uint8 = uint8.empty;   % flag for type of result in y axis
        
        % Curves data
        n_curves uint8  = uint8.empty;    % number of curves in graph
        names    string = string.empty;   % vector of curves names
        px       uint32 = uint32.empty;   % vector of particles IDs for x axis result
        py       uint32 = uint32.empty;   % vector of particles IDs for y axis result
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
            this.plotData(drv);
            this.writeData(drv);
        end
        
        %------------------------------------------------------------------
        function plotData(this,drv)
            if (isempty(this.n_curves))
                return;
            end
            
            % Create new figure
            fig = figure;
            
            % Set properties
            grid on;
            hold on;
            movegui(fig,'center');
            title(this.gtitle);
            
            % Plot curves
            leg = strings(this.n_curves,1);
            for i = 1:this.n_curves
                % Get X,Y data arrays
                x = this.getData(drv,this.res_x,this.px(i));
                y = this.getData(drv,this.res_y,this.py(i));
                
                % Remove NaN (Not a Number) and adjust array sizes
                % (both vectors return with the same size)
                [x,y,idx] = this.removeNaN(x,y);
                
                % Check data consistency
                if (idx == 0)
                    warning('off','backtrace');
                    warning('Curve "%s" of graph "%s" has no valid results and was not ploted.',this.names(i),this.gtitle);
                    warning('on','backtrace');
                    continue;
                end
                
                % Plot curve
                plot(x,y);
                leg(i) = this.names(i);
            end
            
            % Set legend
            warning off MATLAB:legend:IgnoringExtraEntries
            legend(leg);
            
            % Save picture
            file_name = strcat(drv.path,this.gtitle,'.png');
            saveas(gcf,file_name);
        end
        
        %------------------------------------------------------------------
        function writeData(this,drv)
            if (isempty(this.n_curves))
                return;
            end
            
            % Create new file
            file_name = strcat(drv.path,this.gtitle,'.txt');
            fid = fopen(file_name,'w');
            
            % Write curves
            for i = 1:this.n_curves
                % Write curve name
                fprintf(fid,'%s\n',this.names(i));
                
                % Get X,Y data arrays
                x = this.getData(drv,this.res_x,this.px(i));
                y = this.getData(drv,this.res_y,this.py(i));
                
                % Remove NaN (Not a Number) and adjust array sizes
                % (both vectors return with the same size)
                [x,y,idx] = this.removeNaN(x,y);
                
                % Check data consistency
                if (idx == 0)
                    continue;
                end
                
                % Write values
                for j = 1:length(x)
                    fprintf(fid,'%.10f %.10f\n',x(j),y(j));
                end
                fprintf(fid,'\n');
            end
            
            % Close file
            fclose(fid);
        end
        
        %------------------------------------------------------------------
        function R = getData(~,drv,res,p)
            switch res
                case drv.result.TIME
                    R = drv.result.times;
                case drv.result.STEP
                    R = drv.result.steps;
                case drv.result.RADIUS
                    R = drv.result.radius(p,:);
                case drv.result.MASS
                    R = drv.result.mass(p,:);
                case drv.result.COORDINATE_X
                    R = drv.result.coord_x(p,:);
                case drv.result.COORDINATE_Y
                    R = drv.result.coord_y(p,:);
                case drv.result.ORIENTATION
                    R = drv.result.orientation(p,:);
                case drv.result.FORCE_MOD
                    x = drv.result.force_x(p,:);
                    y = drv.result.force_y(p,:);
                    R = vecnorm([x;y]);
                case drv.result.FORCE_X
                    R = drv.result.force_x(p,:);
                case drv.result.FORCE_Y
                    R = drv.result.force_y(p,:);
                case drv.result.TORQUE
                    R = drv.result.torque(p,:);
                case drv.result.VELOCITY_MOD
                    x = drv.result.velocity_x(p,:);
                    y = drv.result.velocity_y(p,:);
                    R = vecnorm([x;y]);
                case drv.result.VELOCITY_X
                    R = drv.result.velocity_x(p,:);
                case drv.result.VELOCITY_Y
                    R = drv.result.velocity_y(p,:);
                case drv.result.VELOCITY_ROT
                    R = drv.result.velocity_rot(p,:);
                case drv.result.ACCELERATION_MOD
                    x = drv.result.acceleration_x(p,:);
                    y = drv.result.acceleration_y(p,:);
                    R = vecnorm([x;y]);
                case drv.result.ACCELERATION_X
                    R = drv.result.acceleration_x(p,:);
                case drv.result.ACCELERATION_Y
                    R = drv.result.acceleration_y(p,:);
                case drv.result.ACCELERATION_ROT
                    R = drv.result.acceleration_rot(p,:);
                case drv.result.TEMPERATURE
                    R = drv.result.temperature(p,:);
                case drv.result.HEAT_RATE
                    R = drv.result.heat_rate(p,:);
                case drv.result.AVG_VELOCITY_MOD
                    R = drv.result.avg_velocity_mod;
                case drv.result.AVG_VELOCITY_ROT
                    R = drv.result.avg_velocity_rot;
                case drv.result.AVG_ACCELERATION_MOD
                    R = drv.result.avg_acceleration_mod;
                case drv.result.AVG_ACCELERATION_ROT
                    R = drv.result.avg_acceleration_rot;
                case drv.result.AVG_TEMPERATURE
                    R = drv.result.avg_temperature;
                case drv.result.MIN_VELOCITY_MOD
                    R = drv.result.min_velocity_mod;
                case drv.result.MAX_VELOCITY_MOD
                    R = drv.result.max_velocity_mod;
                case drv.result.MIN_VELOCITY_ROT
                    R = drv.result.min_velocity_rot;
                case drv.result.MAX_VELOCITY_ROT
                    R = drv.result.max_velocity_rot;
                case drv.result.MIN_ACCELERATION_MOD
                    R = drv.result.min_acceleration_mod;
                case drv.result.MAX_ACCELERATION_MOD
                    R = drv.result.max_acceleration_mod;
                case drv.result.MIN_ACCELERATION_ROT
                    R = drv.result.min_acceleration_rot;
                case drv.result.MAX_ACCELERATION_ROT
                    R = drv.result.max_acceleration_rot;
                case drv.result.MIN_TEMPERATURE
                    R = drv.result.min_temperature;
                case drv.result.MAX_TEMPERATURE
                    R = drv.result.max_temperature;
                case drv.result.TOT_HEAT_RATE_ALL
                    R = drv.result.tot_heat_rate_all;
                case drv.result.TOT_CONDUCTION_DIRECT
                    R = drv.result.tot_conduction_direct;
                case drv.result.TOT_CONDUCTION_INDIRECT
                    R = drv.result.tot_conduction_indirect;
            end
        end
        
        %------------------------------------------------------------------
        function [x,y,idx] = removeNaN(~,x,y)
            nanx = find(isnan(x),1);
            nany = find(isnan(y),1);
            idx  = length(x);
            if (~isempty(nanx))
                idx = min(idx,nanx-1);
            end
            if (~isempty(nany))
                idx = min(idx,nany-1);
            end
            x = x(1:idx);
            y = y(1:idx);
        end
    end
end