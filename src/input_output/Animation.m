%% Animation class
%
%% Description
%
% This is a handle class responsible for creating, displaying and saving
% an animation of a required result.
%
% Three types of animated results are available:
%
% * *Motion*: Shows only the motion of particles and walls.
%
% * *Scalar*: Shows the motion of the elements and fills the particles with
% a color scale to represent a scalar result.
%
% * *Vector*: Shows the motion of the elements and uses arrows to indicate
% the direction and intensity of a vector result.
%
classdef Animation < handle
    %% Constant values: animation types
    properties (Constant = true, Access = public)
        MOTION = uint8(1);   % Particles motion with no result indication
        SCALAR = uint8(2);   % Particles with color to indicate scalar result
        VECTOR = uint8(3);   % Particles with arrow to indicate vector result
    end
    
    %% Constant values: default drawing properties
    properties (Constant = true, Access = public)
        % Colors
        col_pedge = char('k');   % color of particle edge
        col_pfill = char('w');   % color of particle interior when not showing scalar result
        col_wall  = char('k');   % color of wall when not showing scalar result
        col_bbox  = char('b');   % color of bounding box limit
        col_sink  = char('r');   % color of sink limit
        
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
        res_type   uint8  = uint8.empty;    % flag for result type
        anim_type  uint8  = uint8.empty;    % flag for animation type 
        anim_title string = string.empty;   % animation title
        
        % Results: motion (common to all animation types)
        times    double = double.empty;   % array of simulation times of each step
        coord_x  double = double.empty;   % array of particles x coordinates
        coord_y  double = double.empty;   % array of particles y coordinates
        radius   double = double.empty;   % array of particles radius
        wall_pos double = double.empty;   % array of wall positions
        
        % Results: scalar
        res_part  double = double.empty;   % array of scalar result to be exhibited for particles
        res_wall  double = double.empty;   % array of scalar result to be exhibited for walls
        res_range double = double.empty;   % array of results range (minimum to maximum value)
        col_range double = double.empty;   % array of colorbar range (minimum to maximum value)
        
        % Results: vector
        res_vecx  double = double.empty;   % array of x vector result to be exhibited
        res_vecy  double = double.empty;   % array of y vector result to be exhibited
        arrow_fct double = double.empty;   % Multiplication factor to define vetor arrow size
        
        % Options
        play logical = logical.empty;   % flag for playing animation in Matlab after creation
        pids logical = logical.empty;   % flag for ploting particles IDs
        bbox double  = double.empty;    % fixed limits for animation
        
        % Animation components
        fig    matlab.ui.Figure = matlab.ui.Figure.empty;             % figure handle
        frames struct           = struct('cdata',[],'colormap',[]);   % array of movie frames
        fps    double           = double.empty;                       % movie frame rate
    end
    
    %% Constructor method
    methods
        function this = Animation()
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
        function curConfig(this,drv,prefix)
            % Create figure
            f = figure('name',[prefix,' ','Configuration']);
            
            % Set figure properties
            f.Visible  = 'off';
            f.Units    = 'normalized';
            f.Position = [0.1 0.1 0.8 0.8];
            
            % Set axes properties
            axis(gca,'equal');
            hold on;
            if (~isempty(this.bbox))
                xlim(this.bbox(1:2))
                ylim(this.bbox(3:4))
            else
                this.setBBox(drv);
            end
            
            % Get last stored results
            col = drv.result.idx;
            this.times    = drv.result.times(col);
            this.coord_x  = drv.result.coord_x(:,col);
            this.coord_y  = drv.result.coord_y(:,col);
            this.radius   = drv.result.radius(:,col);
            this.wall_pos = drv.result.wall_position(:,col);
            
            % Check if there are results at current time
            if (isnan(this.times))
                close f;
                return;
            end
            
            % Get default result to show for each type of analysis
            if (drv.type == drv.MECHANICAL)
                title(gca,[prefix,' ',sprintf('Velocities - Time: %.3f',drv.time)]);
                this.anim_type = this.MOTION;
                this.drawFrame(drv,1);
                
            else
                title(gca,[prefix,' ',sprintf('Temperatures - Time: %.3f',drv.time)]);
                this.anim_type = this.SCALAR;
                
                % Get last stored temperatures (must be available)
                if (~isempty(drv.result.temperature(:,col)))
                    this.res_part = drv.result.temperature(:,col);
                end
                if (~isempty(drv.result.wall_temperature(:,col)))
                    this.res_wall = drv.result.wall_temperature(:,col);
                end
                
                % Set result and colorbar ranges (always automatic for current configuration)
                this.setRange();
                
                % Draw model components
                this.drawFrame(drv,1);
            end
            
            % Show figure
            f.Visible = 'on';
            pause(1);
        end
        
        %------------------------------------------------------------------
        function animate(this,drv)
            % Create new figure
            this.fig = figure('Name',this.anim_title);
            
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
            else
                this.setBBox(drv);
            end
            
            % Set motion results (always needed to show model animation)
            this.times    = drv.result.times;
            this.coord_x  = drv.result.coord_x;
            this.coord_y  = drv.result.coord_y;
            this.radius   = drv.result.radius;
            this.wall_pos = drv.result.wall_position;
            
            % Set type and create animation
            this.setType(drv)
            this.createAnimation(drv);
            
            % Save movie file
            file_name = strcat(drv.path,'\',this.anim_title);
            writer = VideoWriter(file_name,'MPEG-4');
            writer.FrameRate = this.fps;
            open(writer);
            writeVideo(writer,this.frames);
            close(writer)
        end
        
        %------------------------------------------------------------------
        function createAnimation(this,drv)
            if (this.anim_type == this.SCALAR)
                this.setRange();
            elseif (this.anim_type == this.VECTOR)
                this.setArrowSize();
            end
            
            % Get total number of valid movie frames
            nf = drv.result.idx;
            if (isnan(this.times(nf)))
                nf = find(isnan(this.times)) - 1;
            end
            
            % Preallocate movie frames array
            frams(nf) = struct('cdata',[],'colormap',[]);
            
            % Generate movie frames (one for each results storage time)
            tim = this.times(1:nf);
            tit = this.anim_title;
            for i = 1:nf                
                set(0,'CurrentFigure',this.fig)
                cla;
                title(gca,strcat(tit,sprintf(' - Time: %.3f',tim(i))));
                this.drawFrame(drv,i);
                frams(i) = getframe(this.fig);
            end
            this.frames = frams;
            
            % Compute frame rate (frames / second)
            this.fps = ceil(nf/drv.time);
            if (this.fps > 100)
                this.fps = 100;
            elseif (this.fps < 1)
                this.fps = 1;
            end
        end
        
        %------------------------------------------------------------------
        function showAnimation(this)
            if(this.play)
                fprintf('\nShowing animation "%s"...\n',this.anim_title);
                this.fig.Visible = 'on';
                movie(this.fig,this.frames,999,this.fps);
            end
        end
        
        %------------------------------------------------------------------
        function drawFrame(this,drv,f)
            % Draw particles
            this.drawParticles(drv,f);
            
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
        function drawParticles(this,drv,f)
            for i = 1:drv.n_particles
                % Check if particle exists at this frame time
                % (radius should be always available for existing particles)
                if (isnan(this.radius(i,f)))
                    continue
                end
                
                % Draw particle with selected result
                switch this.anim_type
                    case this.MOTION
                        this.drawParticleMotion(i,f);
                    case this.SCALAR
                        this.drawParticleScalar(i,f);
                    case this.VECTOR
                        this.drawParticleVector(i,f);
                end
                
                % Show ID number
                if (this.pids &&...
                    ~isnan(this.coord_x(i,f)) && ~isnan(this.coord_y(i,f)))
                    x = this.coord_x(i,f);
                    y = this.coord_y(i,f);
                    text(x,y,int2str(i),'FontSize',this.id_size);
                end
            end
        end
    end
    
    %% Public methods: auxiliary methods
    methods
        %------------------------------------------------------------------
        function setType(this,drv)
            switch this.res_type
                % Motion
                case drv.result.MOTION
                    this.anim_type = this.MOTION;
                    this.res_part  = drv.result.orientation;
                
                % Scalar
                case drv.result.RADIUS
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.radius;
                    
                case drv.result.MASS
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.mass;
                    
                case drv.result.COORDINATE_X
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.coord_x;
                    
                case drv.result.COORDINATE_Y
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.coord_y;
                    
                case drv.result.ORIENTATION
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.orientation;
                    
                case drv.result.FORCE_MOD
                    this.anim_type = this.SCALAR;
                    x = drv.result.force_x;
                    y = drv.result.force_y;
                    this.res_part = sqrt(x.^2+y.^2);
                    
                case drv.result.FORCE_X
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.force_x;
                    
                case drv.result.FORCE_Y
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.force_y;
                    
                case drv.result.TORQUE
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.torque;
                    
                case drv.result.VELOCITY_MOD
                    this.anim_type = this.SCALAR;
                    x = drv.result.velocity_x;
                    y = drv.result.velocity_y;
                    this.res_part = sqrt(x.^2+y.^2);
                    
                case drv.result.VELOCITY_X
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.velocity_x;
                    
                case drv.result.VELOCITY_Y
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.velocity_y;
                    
                case drv.result.VELOCITY_ROT
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.velocity_rot;
                    
                case drv.result.ACCELERATION_MOD
                    this.anim_type = this.SCALAR;
                    x = drv.result.acceleration_x;
                    y = drv.result.acceleration_Y;
                    this.res_part = sqrt(x.^2+y.^2);
                    
                case drv.result.ACCELERATION_X
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.acceleration_x;
                    
                case drv.result.ACCELERATION_Y
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.acceleration_y;
                    
                case drv.result.ACCELERATION_ROT
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.acceleration_rot;
                    
                case drv.result.TEMPERATURE
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.temperature;
                    this.res_wall  = drv.result.wall_temperature;
                    
                case drv.result.HEAT_RATE
                    this.anim_type = this.SCALAR;
                    this.res_part  = drv.result.heat_rate;
                    
                % Vector
                case drv.result.FORCE_VEC
                    this.anim_type = this.VECTOR;
                    this.res_vecx  = drv.result.force_x;
                    this.res_vecy  = drv.result.force_y;
                    
                case drv.result.VELOCITY_VEC
                    this.anim_type = this.VECTOR;
                    this.res_vecx  = drv.result.velocity_x;
                    this.res_vecy  = drv.result.velocity_y;
                    
                case drv.result.ACCELERATION_VEC
                    this.anim_type = this.VECTOR;
                    this.res_vecx  = drv.result.acceleration_x;
                    this.res_vecy  = drv.result.acceleration_y;
            end
        end
        
        %------------------------------------------------------------------
        function setBBox(~,drv)
            % Initialize axes limits
            if (drv.n_particles ~= 0 || drv.n_walls ~= 0)
                xmin =  inf;
                ymin =  inf;
                xmax = -inf;
                ymax = -inf;
            else
                xmin = -1;
                ymin = -1;
                xmax =  1;
                ymax =  1;
            end
            
            % Compute axes limits
            for i = 1:drv.n_particles
                [xmin_p,ymin_p,xmax_p,ymax_p] = drv.particles(i).getBBoxLimits();
                xmin = min(xmin,xmin_p);
                ymin = min(ymin,ymin_p);
                xmax = max(xmax,xmax_p);
                ymax = max(ymax,ymax_p);
            end
            for i = 1:drv.n_walls
                [xmin_w,ymin_w,xmax_w,ymax_w] = drv.walls(i).getBBoxLimits();
                xmin = min(xmin,xmin_w);
                ymin = min(ymin,ymin_w);
                xmax = max(xmax,xmax_w);
                ymax = max(ymax,ymax_w);
            end
            
            % Create margin
            dx   = xmax-xmin;
            dy   = ymax-ymin;
            xmin = xmin - dx/10;
            ymin = ymin - dx/10;
            xmax = xmax + dy/10;
            ymax = ymax + dy/10;
            
            % Set axes limits
            xlim([xmin,xmax])
            ylim([ymin,ymax])
        end
        
        %------------------------------------------------------------------
        function [min_val,max_val] = scalarValueLimits(this)
            % Limits of particles results
            if (~isempty(this.res_part))
                min_val_p = min(this.res_part(:));
                max_val_p = max(this.res_part(:));
            else
                min_val_p =  inf;
                max_val_p = -inf;
            end
            
            % Limits of walls results
            if (~isempty(this.res_wall))
                min_val_w = min(this.res_wall(:));
                max_val_w = max(this.res_wall(:));
            else
                min_val_w =  inf;
                max_val_w = -inf;
            end
            
            % Total limits of results
            min_val = min([min_val_p,min_val_w]);
            max_val = max([max_val_p,max_val_w]);
            
            % Treat inf and NaN values
            if ((isinf(min_val) && isinf(max_val)) || (isnan(min_val) && isnan(max_val)))
                min_val = -1;
                max_val = +1;
            elseif (isinf(min_val) || isnan(min_val))
                min_val = max_val - 1;
            elseif (isinf(max_val) || isnan(max_val))
                max_val = min_val + 1;
            end
            
            % Treat equal values
            if (min_val == max_val)
                min_val = min_val - 1;
                max_val = max_val + 1;
            end
        end
        
        %------------------------------------------------------------------
        function setRange(this)
            % Compute result limits
            [min_val,max_val] = this.scalarValueLimits();
            
            % Set result range
            if (isempty(this.res_range))
                this.res_range = [min_val,max_val];
            end
            
            % Set colorbar range
            this.col_range = linspace(this.res_range(1),this.res_range(2),256);
            colormap jet;
            caxis([this.res_range(1),this.res_range(2)]);
            colorbar;
        end
        
        %------------------------------------------------------------------
        function setArrowSize(this)
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
            
            % Multiplication factor
            if (max_vec ~= 0 && ~isnan(max_vec))
                this.arrow_fct = 0.1 * d/max_vec;
            else
                this.arrow_fct = 0;
            end
        end
    end
    
    %% Public methods: plotting methods
    methods
        %------------------------------------------------------------------
        function drawParticleMotion(this,i,j)
            % Always check valid data for safety
            if (isnan(this.coord_x(i,j)) || isnan(this.coord_y(i,j)))
                return;
            end
            
            % Position
            x   = this.coord_x(i,j);
            y   = this.coord_y(i,j);
            r   = this.radius(i,j);
            pos = [x-r,y-r,2*r,2*r];
            
            % Plot particle (rectangle with rounded sides)
            c = this.col_pedge;
            w = this.wid_pedge;
            s = this.sty_pedge;
            rectangle('Position',pos,'Curvature',[1 1],'EdgeColor',c,'LineWidth',w,'LineStyle',s,'FaceColor','none');
            
            % Plot orientation (default particle result of motion animations)
            if (~isempty(this.res_part) && ~isnan(this.res_part(i,j)))
                o = this.res_part(i,j);
                p = [x,y]+[r*cos(o),r*sin(o)];
                line([x,p(1)],[y,p(2)],'Color',c,'LineWidth',w,'LineStyle',s);
            end
        end
        
        %------------------------------------------------------------------
        function drawParticleScalar(this,i,j)
            % Always check valid data for safety
            if (isnan(this.coord_x(i,j)) || isnan(this.coord_y(i,j)))
                return;
            end
            
            % Position
            x   = this.coord_x(i,j);
            y   = this.coord_y(i,j);
            r   = this.radius(i,j);
            rr  = this.res_range;
            cr  = this.col_range;
            pos = [x-r,y-r,2*r,2*r];
            
            % Color according to result
            if (~isempty(this.res_part) &&...
                all(this.res_part(i,j) >= rr(1) & this.res_part(i,j) <= rr(2)))
                clr = interp1(cr,colormap,this.res_part(i,j));
            else
                clr = this.col_pfill;
            end
            
            % Plot particle (rectangle with rounded sides)
            c = this.col_pedge;
            w = this.wid_pedge;
            s = this.sty_pedge;
            rectangle('Position',pos,'Curvature',[1 1],'EdgeColor',c,'LineWidth',w,'LineStyle',s,'FaceColor',clr);
        end
        
        %------------------------------------------------------------------
        function drawParticleVector(this,i,j)
            % Always check valid data for safety
            if (isnan(this.coord_x(i,j)) || isnan(this.coord_y(i,j)))
                return;
            end
            
            % Position
            x   = this.coord_x(i,j);
            y   = this.coord_y(i,j);
            r   = this.radius(i,j);
            pos = [x-r,y-r,2*r,2*r];
            
            % Plot particle (rectangle with rounded sides)
            c = this.col_pedge;
            w = this.wid_pedge;
            s = this.sty_pedge;
            rectangle('Position',pos,'Curvature',[1 1],'EdgeColor',c,'LineWidth',w,'LineStyle',s,'FaceColor','none');
            
            % Plot vector arrow
            if (~isempty(this.res_vecx)    && ~isempty(this.res_vecy) &&...
                ~isnan(this.res_vecx(i,j)) && ~isnan(this.res_vecy(i,j)))
                vx = this.arrow_fct * this.res_vecx(i,j);
                vy = this.arrow_fct * this.res_vecy(i,j);
                line([x,x+vx],[y,y+vy],'Color',c,'LineWidth',w,'LineStyle',s);
            end
        end
        
        %------------------------------------------------------------------
        function drawWall(this,wall,j)
            w  = this.wid_wall;
            s  = this.sty_wall;
            rr = this.res_range;
            cr = this.col_range;
            
            % Color according to result
            if (~isempty(this.res_wall) &&...
                ~wall.insulated         &&...
                all(this.res_wall(wall.id,j) >= rr(1) & this.res_wall(wall.id,j) <= rr(2)))
                c = interp1(cr,colormap,this.res_wall(wall.id,j));
            else
                c = this.col_wall;
            end
            
            % Row ID
            row = 4 * (wall.id-1) + 1;
            
            switch wall.type
                case wall.LINE
                    x1 = this.wall_pos(row+0,j);
                    y1 = this.wall_pos(row+1,j);
                    x2 = this.wall_pos(row+2,j);
                    y2 = this.wall_pos(row+3,j);
                    line([x1,x2],[y1,y2],'Color',c,'LineWidth',w,'LineStyle',s);
                
                case wall.CIRCLE
                    x = this.wall_pos(row+0,j);
                    y = this.wall_pos(row+1,j);
                    r = this.wall_pos(row+2,j);
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