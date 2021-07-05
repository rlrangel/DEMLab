%% Animate class
%
%% Description
%
%% Implementation
%
classdef Animate < handle
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        atitle string = string.empty;   % animation title
        path   string = string.empty;   % path to model folder
        
        % Results
        res_type uint8  = uint8.empty;    % flag for type of result
        res_data double = double.empty;   % matrix of result to be exhibited
        coord_x  double = double.empty;   % matrix of particles x coordinates
        coord_y  double = double.empty;   % matrix of particles y coordinates
        radius   double = double.empty;   % matrix of particles radius
        
        % Options
        pids logical = logical.empty;   % flag for ploting particles IDs
    end
    
    %% Constructor method
    methods
        function this = Animate()
            this.setDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.pids = false;
        end
        
        %------------------------------------------------------------------
        function execute(this,drv)
            % Create a new window
            anim = figure;
            
            % Set properties
            movegui(anim,'center');
            title(this.atitle);
            axis(gca,'equal');
            set(gca,'DataAspectRatio',[1 1 1],'Colormap',jet);
            set(gca,'NextPlot','replaceChildren');
            
            % Get needed results
            this.setResData(drv,this.res_type);
            nout = size(this.res_data,2);
            
            % Preallocate movie frames array
            M(nout) = struct('cdata',[],'colormap',[]);
            
            % Generate movie frames
            for i = 1:nout
                %clf;
                this.drawMovieFrame(drv,i);
                drawnow;
                M(i) = getframe;
            end
            
            % Play movie
            movie(M);
        end
        
        %------------------------------------------------------------------
        function setResData(this,drv,res)
            % Set coordinates and radius (always needed to show model animation)
            this.coord_x = drv.result.coord_x;
            this.coord_y = drv.result.coord_y;
            this.radius  = drv.result.radius;
            
            % Get target result
            switch res
                case drv.result.RADIUS
                    this.res_data = drv.result.radius;
                case drv.result.FORCE_MOD
                    this.res_data = drv.result.force_mod;
                case drv.result.FORCE_X
                    this.res_data = drv.result.force_x;
                case drv.result.FORCE_Y
                    this.res_data = drv.result.force_y;
                case drv.result.TORQUE
                    this.res_data = drv.result.torque;
                case drv.result.COORDINATE_X
                    this.res_data = drv.result.coord_x;
                case drv.result.COORDINATE_Y
                    this.res_data = drv.result.coord_y;
                case drv.result.ORIENTATION
                    this.res_data = drv.result.orientation;
                case drv.result.MOTION
                    this.res_data = drv.result.orientation;
                case drv.result.VELOCITY_MOD
                    this.res_data = drv.result.velocity_mod;
                case drv.result.VELOCITY_X
                    this.res_data = drv.result.velocity_x;
                case drv.result.VELOCITY_Y
                    this.res_data = drv.result.velocity_y;
                case drv.result.VELOCITY_ROT
                    this.res_data = drv.result.velocity_rot;
                case drv.result.ACCELERATION_MOD
                    this.res_data = drv.result.acceleration_mod;
                case drv.result.ACCELERATION_X
                    this.res_data = drv.result.acceleration_x;
                case drv.result.ACCELERATION_Y
                    this.res_data = drv.result.acceleration_y;
                case drv.result.ACCELERATION_ROT
                    this.res_data = drv.result.acceleration_rot;
                case drv.result.TEMPERATURE
                    this.res_data = drv.result.temperature;
                case drv.result.HEAT_RATE
                    this.res_data = drv.result.heat_rate;
            end
        end
        
        %------------------------------------------------------------------
        function drawMovieFrame(this,drv,step)
            np = size(this.res_data,1);
            
            % Draw particles
            for i = 1:np
                x = this.coord_x(i,step);
                y = this.coord_y(i,step);
                r = this.coord_y(i,step);
                plot(x,y);
                hold on;
            end
            
            % Draw walls
            
            
            % Draw bounding box and sinks
            
            
        end
    end
end