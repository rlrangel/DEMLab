%% ContactForceNormal_DiskDisk_LinearViscoElastic class
%
%% Description
%
%% Implementation
%
classdef ContactForceNormal_DiskDisk_LinearViscoElastic < ContactForceNormal
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        stiff_formula   int8    = uint8.empty;     % flag for type of stiffness formulation
        remove_cohesion logical = logical.empty;   % flag for removing artificial cohesion
    end
    
    %% Constructor method
    methods
        function this = ContactForceNormal_DiskDisk_LinearViscoElastic()
            this = this@ContactForceNormal(ContactForceNormal.DISK_DISK_VISCOELASTIC_LINEAR);
            this.applyDefaultProps();
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function applyDefaultProps(this)
            this.stiff_formula   = this.ENERGY;
            this.remove_cohesion = true;
        end
    end
end