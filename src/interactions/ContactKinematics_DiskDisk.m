%% ContactKinematics_DiskDisk class
%
%% Description
%
%% Implementation
%
classdef ContactKinematics_DiskDisk < ContactKinematics
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = ContactKinematics_DiskDisk()
            this = this@ContactKinematics(ContactKinematics.DISK_DISK);
        end
    end
    
    %% Public methods
    methods
        
    end
end