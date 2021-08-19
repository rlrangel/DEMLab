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
        
        % Behavior flags
        insulated logical = logical.empty;   % flag for insulated interaction (no heat exchange)
        
        % Effective parameters
        eff_radius  double = double.empty;
        eff_mass    double = double.empty;
        eff_young   double = double.empty;
        eff_shear   double = double.empty;
        eff_conduct double = double.empty;
        
        % Average parameters
        avg_poisson double = double.empty;   % Simple average of Poisson ratios
        avg_conduct double = double.empty;   % Weighted average of particles conductivity (not considering wall)
        
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
        function setFixParamsTherm(this,drv)
            if (this.insulated)
                return;
            end
            if (~isempty(this.dconduc) && this.kinemat.is_contact)
                this.dconduc = this.dconduc.setFixParams(this);
            end
            if (~isempty(this.iconduc))
                this.iconduc = this.iconduc.setFixParams(this,drv);
            end
        end
        
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
        function setCteParamsTherm(this,drv)
            if (this.insulated)
                return;
            end
            if (~isempty(this.dconduc) && this.kinemat.is_contact)
                this.dconduc = this.dconduc.setCteParams(this);
            end
            if (~isempty(this.iconduc))
                this.iconduc = this.iconduc.setCteParams(this,drv);
            end
        end
        
        %------------------------------------------------------------------
        function evalResultsMech(this)
            if (~isempty(this.cforcen))
                this.cforcen = this.cforcen.evalForce(this);
                this.kinemat.addContactForceNormalToParticles(this);
            end
            if (~isempty(this.cforcet))
                this.cforcet = this.cforcet.evalForce(this);
                this.kinemat.addContactForceTangentToParticles(this);
                this.kinemat.addContactTorqueTangentToParticles(this);
            end
            if (~isempty(this.rollres))
                this.rollres = this.rollres.evalTorque(this);
                this.kinemat.addRollResistTorqueToParticles(this);
            end
        end
        
        %------------------------------------------------------------------
        function evalResultsTherm(this,drv)
            if (this.insulated)
                return;
            end
            if (~isempty(this.dconduc) && this.kinemat.is_contact)
                this.dconduc = this.dconduc.evalHeatRate(this);
                this.kinemat.addDirectConductionToParticles(this);
            end
            if (~isempty(this.iconduc))
                this.iconduc = this.iconduc.evalHeatRate(this,drv);
                this.kinemat.addIndirectConductionToParticles(this);
            end
        end
    end
end