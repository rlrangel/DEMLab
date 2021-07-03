%% Scheme_ForwardEuler class
%
%% Description
%
%% Implementation
%
classdef Scheme_ForwardEuler < Scheme
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Scheme_ForwardEuler()
            this = this@Scheme(Scheme.FORWARD_EULER);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        
    end
end