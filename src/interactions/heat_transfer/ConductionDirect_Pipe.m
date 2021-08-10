%% ConductionDirect_Pipe class
%
%% Description
%
% This is a sub-class of the <conductiondirect.html ConductionDirect>
% class for the implementation of the *Thermal Pipe* direct heat
% conduction model.
%
% DESCRIPTION HERE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%
% The heat transfer is given by:
%
% EQUATION HERE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%
% *Notation*:
%
% *References*:
%
classdef ConductionDirect_Pipe < ConductionDirect
    %% Constructor method
    methods
        function this = ConductionDirect_Pipe()
            this = this@ConductionDirect(ConductionDirect.PIPE);
            this = this.setDefaultProps();
        end
    end
    
    %% Public methods: implementation of super-class declarations
    methods
        %------------------------------------------------------------------
        function this = setDefaultProps(this)
            
        end
        
        %------------------------------------------------------------------
        function this = setCteParams(this,~)
            
        end
        
        %------------------------------------------------------------------
        function this = evalHeatRate(this,int)
            
        end
    end
end