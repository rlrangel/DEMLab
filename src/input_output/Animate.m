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
        
        % Results: general
        res_type  uint8  = uint8.empty;    % flag for type of result
        np        uint32 = uint32.empty;   % total number of particles
        nf        uint32 = uint32.empty;   % total number of frames
        
        % Results: common
        times    double = double.empty;   % array of simulation times of each step
        coord_x  double = double.empty;   % array of particles x coordinates
        coord_y  double = double.empty;   % array of particles y coordinates
        radius   double = double.empty;   % array of particles radius
        wall_pos double = double.empty;   % array of wall positions
        
        % Results: scalar
        res_range double = double.empty;   % array of results range (minimum to maximum value)
        res_part  double = double.empty;   % array of scalar result to be exhibited for particles
        res_wall  double = double.empty;   % array of scalar result to be exhibited for walls
        
        % Results: vector
        res_vecx  double = double.empty;   % array of x vector result to be exhibited
        res_vecy  double = double.empty;   % array of y vector result to be exhibited
        arrow_fct double = double.empty;   % multiplicator factor to define vetor arrow size
        
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
            this.fig.Visible  = 'off';
            this.fig.Units    = 'normalized';
            this.fig.Position = [0.1 0.1 0.8 0.8];
            
            % Set axes properties
            axis(gca,'equal');
            hold on;
            if (~isempty(this.bbox))
                xlim(this.bbox(1:2))
                ylim(this.bbox(3:4))
            end
            
            % Set common results (always needed to show model animation)
            this.times    = drv.result.times;
            this.coord_x  = drv.result.coord_x;
            this.coord_y  = drv.result.coord_y;
            this.radius   = drv.result.radius;
            this.wall_pos = drv.result.wall_position;
            
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
                    this.res_part = drv.result.orientation;
                    this.type = this.MOTION;
                
                % Scalar
                case drv.result.RADIUS
                    this.res_part = drv.result.radius;
                    this.type = this.SCALAR;
                case drv.result.COORDINATE_X
                    this.res_part = drv.result.coord_x;
                    this.type = this.SCALAR;
                case drv.result.COORDINATE_Y
                    this.res_part = drv.result.coord_y;
                    this.type = this.SCALAR;
                case drv.result.ORIENTATION
                    this.res_part = drv.result.orientation;
                    this.type = this.SCALAR;
                case drv.result.FORCE_MOD
                    x = drv.result.force_x;
                    y = drv.result.force_y;
                    this.res_part = vecnorm([x;y]);
                    this.type = this.SCALAR;
                case drv.result.FORCE_X
                    this.res_part = drv.result.force_x;
                    this.type = this.SCALAR;
                case drv.result.FORCE_Y
                    this.res_part = drv.result.force_y;
                    this.type = this.SCALAR;
                case drv.result.TORQUE
                    this.res_part = drv.result.torque;
                    this.type = this.SCALAR;
                case drv.result.VELOCITY_MOD
                    x = drv.result.velocity_x;
                    y = drv.result.velocity_y;
                    this.res_part = vecnorm([x;y]);
                    this.type = this.SCALAR;
                case drv.result.VELOCITY_X
                    this.res_part = drv.result.velocity_x;
                    this.type = this.SCALAR;
                case drv.result.VELOCITY_Y
                    this.res_part = drv.result.velocity_y;
                    this.type = this.SCALAR;
                case drv.result.VELOCITY_ROT
                    this.res_part = drv.result.velocity_rot;
                    this.type = this.SCALAR;
                case drv.result.ACCELERATION_MOD
                    x = drv.result.acceleration_x;
                    y = drv.result.acceleration_Y;
                    this.res_part = vecnorm([x;y]);
                    this.type = this.SCALAR;
                case drv.result.ACCELERATION_X
                    this.res_part = drv.result.acceleration_x;
                    this.type = this.SCALAR;
                case drv.result.ACCELERATION_Y
                    this.res_part = drv.result.acceleration_y;
                    this.type = this.SCALAR;
                case drv.result.ACCELERATION_ROT
                    this.res_part = drv.result.acceleration_rot;
                    this.type = this.SCALAR;
                case drv.result.TEMPERATURE
                    this.res_part = drv.result.temperature;
                    this.res_wall = drv.result.wall_temperature;
                    this.type = this.SCALAR;
                case drv.result.HEAT_RATE
                    this.res_part = drv.result.heat_rate;
                    this.type = this.SCALAR;
                    
                % Vector
                case drv.result.FORCE_VEC
                    this.res_vecx = drv.result.force_x;
                    this.res_vecy = drv.result.force_y;
                    this.type = this.VECTOR;
                case drv.result.VELOCITY_VEC
                    this.res_vecx = drv.result.velocity_x;
                    this.res_vecy = drv.result.velocity_y;
                    this.type = this.VECTOR;
                case drv.result.ACCELERATION_VEC
                    this.res_vecx = drv.result.acceleration_x;
                    this.res_vecy = drv.result.acceleration_y;
                    this.type = this.VECTOR;
            end
        end
        
        %------------------------------------------------------------------
        function createAnimation(this,drv)
            if (this.type == this.SCALAR)
                % Get result range
                min_val_p = min(this.res_part(:));
                max_val_p = max(this.res_part(:));
                min_val_w = min(this.res_wall(:));
                max_val_w = max(this.res_wall(:));
                min_val = min([min_val_p,min_val_w]);
                max_val = max([max_val_p,max_val_w]);
                if (min_val == max_val)
                    min_val = min_val - 1;
                    max_val = max_val + 1;
                end
                this.res_range = linspace(min_val,max_val,256);
                
                % Set colormap
                colormap jet;
                caxis([min_val,max_val]);
                colorbar;
            
            % Arrow size for vector results
            elseif (this.type == this.VECTOR)
                % Maximum vector norm value
                x = this.res_vecx;
                y = this.res_vecy;
                max_vec = max(sqrt(x.^2+y.^2));
                
                % Figure size
                limitx = xlim;
                limity = ylim;
                dx = limitx(2)-limitx(1);
                dy = limity(2)-limity(1);
                d  = sqrt(dx^2+dy^2);
                
                % Multiplicator factor
                this.arrow_fct = 0.1 * d/max_vec;
            end
            
            % Number of particles and frames
            this.np = size(this.radius,1);
            this.nf = size(this.radius,2);
            
            % Preallocate movie frames array
            frams(this.nf) = struct('cdata',[],'colormap',[]);
            
            % Generate movie frames
            tim = this.times;
            tit = this.atitle;
            for i = 1:this.nf
                cla;
                title(gca,strcat(tit,sprintf(' - Time: %.3f',tim(i))));
                this.drawMovieFrame(drv,i);
                frams(i) = getframe(this.fig);
            end
            this.frames = frams;
            
            % Compute frame rate (frames / second)
            this.fps = this.nf/drv.time;
            if (this.fps > 100)
                this.fps = 100;
            end
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
            if (isnan(this.times(1,f)))
                return;
            end
            
            % Draw particles
            for i = 1:this.np
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
                this.drawWall(drv.walls(i),f);
            end
            
            % Draw bounding box
            if (~isempty(drv.bbox))
                if (drv.bbox.isActive(this.times(f)))
                    this.drawBBox(drv.bbox);
                end
            end
            
            % Draw sinks
            for i = 1:length(drv.sink)
                if (drv.sink(i).isActive(this.times(f)))
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
            o = this.res_part(i,j);
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
            clr = interp1(this.res_range,colormap,this.res_part(i,j));
            
            % Plot (rectangle with rounded sides)
            c = this.col_pedge;
            w = this.wid_pedge;
            s = this.sty_pedge;
            rectangle('Position',pos,'Curvature',[1 1],'EdgeColor',c,'LineWidth',w,'LineStyle',s,'FaceColor',clr);
        end
        
        %------------------------------------------------------------------
        function drawParticleVector(this,i,j)
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
            
            % Plot arrow
            vx = this.arrow_fct * this.res_vecx(i,j);
            vy = this.arrow_fct * this.res_vecy(i,j);
            line([x,x+vx],[y,y+vy],'Color',c,'LineWidth',w,'LineStyle',s);
        end
        
        %------------------------------------------------------------------
        function drawWall(this,wall,j)
            w = this.wid_wall;
            s = this.sty_wall;
            
            % Set wall color
            if (isempty(this.res_wall))
                c = this.col_wall;
            else
                c = interp1(this.res_range,colormap,this.res_wall(wall.id,j));
            end
            
            % Column ID
            col = 4 * (wall.id-1) + 1;
            
            switch wall.type
                case wall.LINE
                    x1 = this.wall_pos(col+0,j);
                    y1 = this.wall_pos(col+1,j);
                    x2 = this.wall_pos(col+2,j);
                    y2 = this.wall_pos(col+3,j);
                    line([x1,x2],[y1,y2],'Color',c,'LineWidth',w,'LineStyle',s);
                
                case wall.CIRCLE
                    x = this.wall_pos(col+0,j);
                    y = this.wall_pos(col+1,j);
                    r = this.wall_pos(col+2,j);
                    this.drawCircle(x,y,r,c,w,s);
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