%% Print_Pos class
%
%% Description
%
% This is a sub-class of the <Print.html Print> class for the
% implementation of printing methods for the *.pos* output format.
%
% This output format is used in the regression tests.
%
classdef Print_Pos < Print
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        single_file logical = logical.empty;   % flag for printing all steps in a single file
        results     uint8   = uint8.empty;     % vector of flags for types of results to print
    end
    
    %% Constructor method
    methods
        function this = Print_Pos()
            this = this@Print(Print.POS);
            this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function setDefaultProps(this)
            this.single_file = false;
        end
        
        %------------------------------------------------------------------
        function execute(this,drv)
            % Open file
            if (this.single_file)
                fname = strcat(drv.path_out,drv.name,".pos");
                if (drv.step == 0)
                    fid = fopen(fname,'w'); % clear and write
                else
                    fid = fopen(fname,'a'); % append
                end
            else
                fname = strcat(drv.path_out,drv.name,"_",num2str(drv.step),".pos");
                fid = fopen(fname,'w');
            end
            
            % Check if file could be open
            if (fid < 0)
                fprintf('\nResults could not be printed in step %d.',drv.step);
                fclose(fid);
                return;
            end
            
            % Current step info
            if (this.single_file)
                fprintf(fid,'---------------------------------------------------------------------------\n');
            end
            fprintf(fid,'%%STEP %d\n',drv.step);
            fprintf(fid,'%%TIME %.6f\n',drv.time);
            fprintf(fid,'\n');
            
            % Model numbers info
            fprintf(fid,'%%PARTICLES    %d\n',drv.n_particles);
            fprintf(fid,'%%WALLS        %d\n',drv.n_walls);
            fprintf(fid,'%%INTERACTIONS %d\n',drv.n_interacts);
            fprintf(fid,'\n');
            
            % Print requested results
            for i = 1:length(this.results)
                switch this.results(i)
                    case drv.result.MOTION
                        this.printPosition(drv,fid);
                    case drv.result.VELOCITY_VEC
                        this.printVelocity(drv,fid);
                    case drv.result.ACCELERATION_VEC
                        this.printAcceleration(drv,fid);
                    case drv.result.TEMPERATURE
                        this.printTemperature(drv,fid);
                end
            end
            
            % Close file
            fclose(fid);
        end
    end
    
    %% Public methods: sub-class specifics
    methods
        %------------------------------------------------------------------
        function printPosition(~,drv,fid)
            fprintf(fid,'%%PARTICLE_COORDINATE_ORIENTATION\n');
            for i = 1:drv.n_particles
                p = drv.particles(i);
                fprintf(fid,'%d %.15f %.15f %.15f\n',p.id,p.coord(1),p.coord(2),p.orient);
            end
            fprintf(fid,'\n');
            if (drv.n_walls > 0)
                fprintf(fid,'%%WALL_COORDINATE\n');
                for i = 1:drv.n_walls
                    w = drv.walls(i);
                    if (w.type == w.LINE)
                        fprintf(fid,'%d %.15f %.15f %.15f %.15f\n',w.id,w.coord_ini(1),w.coord_ini(2),w.coord_end(1),w.coord_end(2));
                    elseif (w.type == w.CIRCLE)
                        fprintf(fid,'%d %.15f %.15f\n',w.id,w.center(1),w.radius);
                    end
                end
                fprintf(fid,'\n');
            end
        end
        
        %------------------------------------------------------------------
        function printVelocity(~,drv,fid)
            fprintf(fid,'%%PARTICLE_VELOCITY\n');
            for i = 1:drv.n_particles
                p = drv.particles(i);
                fprintf(fid,'%d %.15f %.15f %.15f\n',p.id,p.veloc_trl(1),p.veloc_trl(2),p.veloc_rot);
            end
            fprintf(fid,'\n');
        end
        
        %------------------------------------------------------------------
        function printAcceleration(~,drv,fid)
            fprintf(fid,'%%PARTICLE_ACCELERATION\n');
            for i = 1:drv.n_particles
                p = drv.particles(i);
                fprintf(fid,'%d %.15f %.15f %.15f\n',p.id,p.accel_trl(1),p.accel_trl(2),p.accel_rot);
            end
            fprintf(fid,'\n');
        end
        
        %------------------------------------------------------------------
        function printTemperature(~,drv,fid)
            fprintf(fid,'%%PARTICLE_TEMPERATURE\n');
            for i = 1:drv.n_particles
                p = drv.particles(i);
                fprintf(fid,'%d %.15f\n',p.id,p.temperature);
            end
            fprintf(fid,'\n');
            if (drv.n_walls > 0)
                fprintf(fid,'%%WALL_TEMPERATURE\n');
                for i = 1:drv.n_walls
                    w = drv.walls(i);
                    fprintf(fid,'%d %.15f\n',w.id,w.temperature);
                end
                fprintf(fid,'\n');
            end
        end
    end
end