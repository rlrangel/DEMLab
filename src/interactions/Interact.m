%% Interact class
%
%% Description
%
% This is a handle heterogeneous super-class for the definition of binary
% interactions between elements (particle-particle and particle-wall).
%
% It stores the effective properties of the interaction and contains
% handles to specific interaction models for kinematics, force and heat
% transfer.
%
classdef Interact < handle & matlab.mixin.Copyable
    %% Public properties
    properties (SetAccess = public, GetAccess = public)
        % Members
        elem1;   % handle to object of the 1st interaction element (defines the sign convection)
        elem2;   % handle to object of the 2nd interaction element
        
        % Effective contact parameters
        eff_radius  double = double.empty;
        eff_mass    double = double.empty;
        eff_young   double = double.empty;
        eff_shear   double = double.empty;
        eff_poisson double = double.empty;
        eff_conduct double = double.empty;
        
        % Mechanical interaction models (value class objects)
        kinemat BinKinematics = BinKinematics.empty;   % general binary kinematics (always exist)
        cforcen ContactForceN = ContactForceN.empty;   % contact force normal (may be empty)
        cforcet ContactForceT = ContactForceT.empty;   % contact force tangent (may be empty)
        rollres RollResist    = RollResist.empty;      % rolling resistance (may be empty)
        
        % Thermal interaction models (value class objects)
        dconduc ConductionDirect   = ConductionDirect.empty;     % direct thermal conduction
        iconduc ConductionIndirect = ConductionIndirect.empty;   % indirect thermal conduction
    end
    
    %% Constructor method
    methods
        function this = Interact()
            
        end
    end
    
    %% Public methods
    methods
        %------------------------------------------------------------------
        function setCteParamsMech(this)
            if (~isempty(this.cforcen))
                this.cforcen = this.cforcen.setCteParams(this);
            end
            if (~isempty(this.cforcet))
                this.cforcet = this.cforcet.setCteParams(this);
            end
            if (~isempty(this.rollres))
                this.rollres = this.rollres.setCteParams(this);
            end
        end
        
        %------------------------------------------------------------------
        function setCteParamsTherm(this)
            if (~isempty(this.dconduc))
                this.dconduc = this.dconduc.setCteParams(this);
            end
            if (~isempty(this.iconduc))
                this.iconduc = this.iconduc.setCteParams(this);
            end
        end
        
        %------------------------------------------------------------------
        function evalResultsMech(this)
            if (~isempty(this.cforcen))
                this.cforcen = this.cforcen.evalForce(this);
            end
            if (~isempty(this.cforcet))
                this.cforcet = this.cforcet.evalForce(this);
            end
            if (~isempty(this.rollres))
                this.rollres = this.rollres.evalTorque(this);
            end
        end
        
        %------------------------------------------------------------------
        function evalResultsTherm(this)
            if (~isempty(this.dconduc))
                this.dconduc = this.dconduc.evalHeatRate(this);
            end
            if (~isempty(this.iconduc))
                this.iconduc = this.iconduc.evalHeatRate(this);
            end
        end
        
        %------------------------------------------------------------------
        function addResultsMech(this)
            if (~isempty(this.cforcen))
                this.kinemat.addContactForceNormalToParticles(this);
            end
            if (~isempty(this.cforcet))
                this.kinemat.addContactForceTangentToParticles(this);
                this.kinemat.addContactTorqueTangentToParticles(this);
            end
            if (~isempty(this.rollres))
                this.kinemat.addRollResistTorqueToParticles(this);
            end
        end
        
        %------------------------------------------------------------------
        function addResultsTherm(this)
            if (~isempty(this.dconduc))
                this.kinemat.addDirectConductionToParticles(this);
            end
            if (~isempty(this.iconduc))
                this.kinemat.addIndirectConductionToParticles(this);
            end
        end
    end
end
