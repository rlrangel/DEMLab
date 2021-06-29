%% ContactForceTangent_DiskDisk_Spring class
%
%% Description
%
%% Implementation
%
classdef ContactForceTangent_DiskDisk_Spring < ContactForceTangent
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        spring_coeff double = double.empty;   % spring coefficient value
    end
    
    %% Constructor method
    methods
        function this = ContactForceTangent_DiskDisk_Spring()
            this = this@ContactForceTangent(ContactForceTangent.DISK_DISK_SPRING);
        end
    end
    
    %% Public methods
    methods
        
    end
end