%% ContactForceT_Spring class
%
%% Description
%
%% Implementation
%
classdef ContactForceT_Spring < ContactForceT
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        spring_coeff double = double.empty;   % spring coefficient value
    end
    
    %% Constructor method
    methods
        function this = ContactForceT_Spring()
            this = this@ContactForceT(ContactForceT.SPRING);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        %------------------------------------------------------------------
        function evalForces(this,interact)
            kt = this.spring_coeff;
            ovlp_t = interact.bin_kinematics.ovlp_t;
            F = kt * ovlp_t;
        end
    end
end