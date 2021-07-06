%% Animate class
%
%% Description
%
%% Implementation
%
classdef Animate < handle
    %% Constant values: animation types
    properties (Constant = true, Access = public)
        MOTION = uint8(2);   % Particles motion with no result indication
        SCALAR = uint8(1);   % Particles with color to indicate scalar result
        VECTOR = uint8(3);   % Particles with arrow to indicate vector result
    end
    
    %% Constant values: drawing properties
    properties (Constant = true, Access = public)
        % Colors
        col_pedge = char('k');   % color of particle edge
        col_wall  = char('k');   % color of wall
        col_bbox  = char('b');   % color of bounding box
        col_sink  = char('r');   % color of sink
        
        % Line widths
        wid_pedge = double(0.1);   % width of particle edge
        wid_wall  = double(2.0);   % width of wall
        wid_bbox  = double(0.5);   % width of bounding box
        wid_sink  = double(0.5);   % width of sink
        
        % Line styles
        sty_pedge = char('-');    % style of particle edge
        sty_wall  = char('-');    % style of wall
        sty_bbox  = char('--');   % style of bounding box
        sty_sink  = char('--');   % style of sink
        
        % Particle ID size
        id_size = double(8);
    end
    
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Identification
        type   uint8  = uint8.empty;    % flag for type of animation
        atitle string = string.empty;   % animation title
        path   string = string.empty;   % path to model folder
        
        % Results
        res_type  uint8  = uint8.empty;    % flag for type of result
        res_data  double = double.empty;   % array of result to be exhibited
        res_range double = double.empty;   % array of results range (minimum to maximum value)
        coord_x   double = double.empty;   % array of particles x coordinates
        coord_y   double = double.empty;   % array of particles y coordinates
        radius    double = double.empty;   % array of particles radius
        times     double = double.empty;   % array of simulation times of each step
        
        % Options
        play logical = logical.empty;   % flag for playing animation in Matlab after creation
        pids logical = logical.empty;   % flag for ploting particles IDs
        bbox double  = double.empty;    % fixed limits for animation
        
        % Animation
        fig    matlab.ui.Figure = matlab.ui.Figure.empty;             % figure handle
        frames struct           = struct('cdata',[],'colormap',[]);   % array of movie frames
        fps    double           = double.empty;                       % movie frame rate
    end
    
    %% Constructor method
    methods
        function this = Animate()
            this.setDefaultProps();
        end
    end
    
    %% Public methods: managing methods
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.play = true;
            this.pids = false;
        end
        
        %------------------------------------------------------------------
        function execute(this,drv)
            % Create new figure
            this.fig = figure;
            
            % Set figure properties
            this.fig.Visible = 'off';
            this.fig.Units = 'normalized';
            this.fig.Position = [0.1 0.1 0.8 0.8];
            
            % Set axes properties
            title(gca,this.atitle);
            axis(gca,'equal');
            hold on;
            if (~isempty(this.bbox))
                xlim(this.bbox(1:2))
                ylim(this.bbox(3:4))
            end
            
            % Set common properties (always needed to show model animation)
            this.coord_x = drv.result.coord_x;
            this.coord_y = drv.result.coord_y;
            this.radius  = drv.result.radius;
            this.times   = drv.result.times;
            
            % Set type and create animation
            this.setType(drv)
            this.createAnimation(drv);
            
            % Save movie file
            file_name = strcat(this.path,'\',this.atitle);
            writer = VideoWriter(file_name,'MPEG-4');
            writer.FrameRate = this.fps;
            open(writer);
            writeVideo(writer,this.frames);
            close(writer)
        end
        
        %------------------------------------------------------------------
        function setType(this,drv)
            switch this.res_type
                % Motion
                case drv.result.MOTION
                    this.res_data = drv.result.orientation;
                    this.type = this.MOTION;
                
                % Scalar
                case drv.result.RADIUS
                    this.res_data = drv.result.radius;
                    this.type = this.SCALAR;
                case drv.result.FORCE_MOD
                    this.res_data = drv.result.force_mod;
                    this.type = this.SCALAR;
                case drv.result.FORCE_X
                    this.res_data = drv.result.force_x;
                    this.type = this.SCALAR;
                case drv.result.FORCE_Y
                    this.res_data = drv.result.force_y;
                    this.type = this.SCALAR;
                case drv.result.TORQUE
                    this.res_data = drv.result.torque;
                    this.type = this.SCALAR;
                case drv.result.COORDINATE_X
                    this.res_data = drv.result.coord_x;
                    this.type = this.SCALAR;
                case drv.result.COORDINATE_Y
                    this.res_data = drv.result.coord_y;
                    this.type = this.SCALAR;
                case drv.result.ORIENTATION
                    this.res_data = drv.result.orientation;
                    this.type = this.SCALAR;
                case drv.result.VELOCITY_MOD
                    this.res_data = drv.result.velocity_mod;
                    this.type = this.SCALAR;
                case drv.result.VELOCITY_X
                    this.res_data = drv.result.velocity_x;
                    this.type = this.SCALAR;
                case drv.result.VELOCITY_Y
                    this.res_data = drv.result.velocity_y;
                    this.type = this.SCALAR;
                case drv.result.VELOCITY_ROT
                    this.res_data = drv.result.velocity_rot;
                    this.type = this.SCALAR;
                case drv.result.ACCELERATION_MOD
                    this.res_data = drv.result.acceleration_mod;
                    this.type = this.SCALAR;
                case drv.result.ACCELERATION_X
                    this.res_data = drv.result.acceleration_x;
                    this.type = this.SCALAR;
                case drv.result.ACCELERATION_Y
                    this.res_data = drv.result.acceleration_y;
                    this.type = this.SCALAR;
                case drv.result.ACCELERATION_ROT
                    this.res_data = drv.result.acceleration_rot;
                    this.type = this.SCALAR;
                case drv.result.TEMPERATURE
                    this.res_data = drv.result.temperature;
                    this.type = this.SCALAR;
                case drv.result.HEAT_RATE
                    this.res_data = drv.result.heat_rate;
                    this.type = this.SCALAR;
            end
        end
        
        %------------------------------------------------------------------
        function createAnimation(this,drv)
            if (this.type == this.SCALAR)
                % Get result range
                min_val = min(this.res_data(:));
                max_val = max(this.res_data(:));
                if (min_val == max_val)
                    min_val = min_val - 1;
                    max_val = max_val + 1;
                end
                this.res_range = linspace(min_val,max_val,256);
                
                % Set colormap
                colormap jet;
                caxis([min_val,max_val]);
                colorbar;
            end
            
            % Preallocate movie frames array
            nframes = size(this.res_data,2);
            this.frames(nframes) = struct('cdata',[],'colormap',[]);
            
            % Generate movie frames
            for i = 1:nframes
                cla;
                this.drawMovieFrame(drv,i);
                this.frames(i) = getframe(this.fig);
            end
            
            % Compute frame rate (frames / second)
            this.fps = nframes/drv.time;
        end
        
        %------------------------------------------------------------------
        function show(this)
            if(this.play)
                this.fig.Visible = 'on';
                movie(this.fig,this.frames,99999,this.fps);
            end
        end
    end
    
    %% Public methods: plotting methods
    methods
        %------------------------------------------------------------------
        function drawMovieFrame(this,drv,f)
            % Number of particles and current frame time
            np = size(this.res_data,1);
            t = this.times(f);
            
            % Draw particles
            for i = 1:np
                if (isnan(this.res_data(i,f)))
                    continue;
                end
                switch this.type
                    case this.MOTION
                        this.drawParticleMotion(i,f);
                    case this.SCALAR
                        this.drawParticleScalar(i,f);
                    case this.VECTOR
                        this.drawParticleVector(i,f);
                end
                
                % Show ID number
                if (this.pids)
                    x = this.coord_x(i,f);
                    y = this.coord_y(i,f);
                    text(x,y,int2str(i),'FontSize',this.id_size);
                end
            end
            
            % Draw walls
            for i = 1:drv.n_walls
                this.drawWall(drv.walls(i));
            end
            
            % Draw bounding box
            if (~isempty(drv.bbox))
                if (drv.bbox.isActive(t))
                    this.drawBBox(drv.bbox);
                end
            end
            
            % Draw sinks
            for i = 1:length(drv.sink)
                if (drv.sink(i).isActive(t))
                    this.drawSink(drv.sink(i));
                end
            end
        end
        
        %------------------------------------------------------------------
        function drawParticleMotion(this,i,j)
            % Position
            x = this.coord_x(i,j);
            y = this.coord_y(i,j);
            r = this.radius(i,j);
            pos = [x-r,y-r,2*r,2*r];
            
            % Plot (rectangle with rounded sides)
            c = this.col_pedge;
            w = this.wid_pedge;
            s = this.sty_pedge;
            rectangle('Position',pos,'Curvature',[1 1],'EdgeColor',c,'LineWidth',w,'LineStyle',s,'FaceColor','none');
            
            % Plot orientation
            o = this.res_data(i,j);
            p = [x,y]+[r*cos(o),r*sin(o)];
            line([x,p(1)],[y,p(2)],'Color',c,'LineWidth',w,'LineStyle',s);
        end
        
        %------------------------------------------------------------------
        function drawParticleScalar(this,i,j)
            % Position
            x   = this.coord_x(i,j);
            y   = this.coord_y(i,j);
            r   = this.radius(i,j);
            pos = [x-r,y-r,2*r,2*r];
            
            % Color according to result
            clr = interp1(this.res_range,colormap,this.res_data(i,j));
            
            % Plot (rectangle with rounded sides)
            c = this.col_pedge;
            w = this.wid_pedge;
            s = this.sty_pedge;
            rectangle('Position',pos,'Curvature',[1 1],'EdgeColor',c,'LineWidth',w,'LineStyle',s,'FaceColor',clr);
        end
        
        %------------------------------------------------------------------
        function drawParticleVector(this,i,j)
            
        end
        
        %------------------------------------------------------------------
        function drawWall(this,wall)
            c = this.col_wall;
            w = this.wid_wall;
            s = this.sty_wall;
            
            switch wall.type
                case wall.LINE2D
                    x1 = wall.coord_ini(1);
                    y1 = wall.coord_ini(2);
                    x2 = wall.coord_end(1);
                    y2 = wall.coord_end(2);
                    line([x1,x2],[y1,y2],'Color',c,'LineWidth',w,'LineStyle',s);
                
                case wall.CIRCLE
                    this.drawCircle(wall.center(1),wall.center(2),wall.radius,c,w,s);
            end
        end
        
        %------------------------------------------------------------------
        function drawBBox(this,bbox)
            c = this.col_bbox;
            w = this.wid_bbox;
            s = this.sty_bbox;
            
            switch bbox.type
                case bbox.RECTANGLE
                    x1  = bbox.limit_min(1);
                    y1  = bbox.limit_min(2);
                    x2  = bbox.limit_max(1);
                    y2  = bbox.limit_max(2);
                    pos = [x1,y1,x2-x1,y2-y1];
                    rectangle(pos,'EdgeColor',c,'LineWidth',w,'LineStyle',s);
                    
                case bbox.CIRCLE
                    this.drawCircle(bbox.center(1),bbox.center(2),bbox.radius,c,w,s);
                    
                case bbox.POLYGON
                    pol = polyshape(bbox.coord_x,bbox.coord_y);
                    plot(pol,'FaceColor','none','EdgeColor',c,'LineWidth',w,'LineStyle',s);
            end
        end
        
        %------------------------------------------------------------------
        function drawSink(this,sink)
            c = this.col_sink;
            w = this.wid_sink;
            s = this.sty_sink;
            
            switch sink.type
                case sink.RECTANGLE
                    x1  = sink.limit_min(1);
                    y1  = sink.limit_min(2);
                    x2  = sink.limit_max(1);
                    y2  = sink.limit_max(2);
                    pos = [x1,y1,x2-x1,y2-y1];
                    rectangle(pos,'EdgeColor',c,'LineWidth',w,'LineStyle',s);
                    
                case sink.CIRCLE
                    this.drawCircle(sink.center(1),sink.center(2),sink.radius,c,w,s);
                    
                case sink.POLYGON
                    pol = polyshape(sink.coord_x,sink.coord_y);
                    plot(pol,'FaceColor','none','EdgeColor',c,'LineWidth',w,'LineStyle',s);
            end
        end
        
        %------------------------------------------------------------------
        function h = drawCircle(~,x,y,r,c,w,s)
            t = 0:pi/50:2*pi;
            x_circle = x + r * cos(t);
            y_circle = y + r * sin(t);
            h = plot(x_circle,y_circle,'Color',c,'LineWidth',w,'LineStyle',s);
        end
    end
end