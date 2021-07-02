%% Scheme_FowardEuler class
%
%% Description
%
%% Implementation
%
classdef Scheme_FowardEuler < Scheme
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        
    end
    
    %% Constructor method
    methods
        function this = Scheme_FowardEuler()
            this = this@Scheme(Scheme.FOWARD_EULER);
        end
    end
    
    %% Public methods: implementation of superclass declarations
    methods
        
    end
end