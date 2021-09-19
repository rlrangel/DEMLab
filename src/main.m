%% DEMLab - Discrete Element Method Laboratory
%
% <<logo_demlab.png>>
%
% This program uses the Discrete Element Method (DEM) to simulate
% particulate systems.
%
% Mechanical, thermal and themomechanical simulations can be performed.
% Only two-dimensional (2D) models are handled.
%
% The program is designed to be a modular and extensible tool to allow
% testing of different models and formulations.
% Code efficiency is not a priority and, therefore, only small-scale
% problems should be simulated.
%
% For more information, visit the
% <https://gitlab.com/rafaelrangel/demlab GitLab repository>.
%
%% Instructions
%
% This is the main script file of the DEMLab program.
%
% To *run a simulation*, execute this script and select an appropriate
% parameters file with the _.json_ extension.
%
% To *load results* from a previously run simulation, execute this
% script and select an appropriate storage file with the _.mat_ extension.
%
% There are two ways to select an input file:
%
% * Provide its complete path thorugh the string variable _file_ in the end
%   of this script (e.g. file = 'C:\...\ProjectParameters.json').
% * Leave the string variable _file_ blank (file = '') and use the
%   selection dialog that appears when running this script (multiple files
%   can be selected).
%
% A folder with the problem name plus the suffix "_out" is created to
% receive the output files.
%
%% OOP classes
%
% This program adopts an Object Oriented Programming (OOP) paradigm.
% The following OOP super-classes are implemented:
%
% * <master.html Master>
% * <driver.html Driver>
% * <search.html Search>
% * <scheme.html Scheme>
% * <particle.html Particle>
% * <wall.html Wall>
% * <modelpart.html ModelPart>
% * <material.html Material>
% * <condition.html Condition>
% * <bbox.html BBox>
% * <sink.html Sink>
% * <interact.html Interact>
% * <binkinematics.html BinKinematics>
% * <contactforcen.html ContactForceN>
% * <contactforcet.html ContactForceT>
% * <rollresist.html RollResist>
% * <areacorrect.html AreaCorrect>
% * <conductiondirect.html ConductionDirect>
% * <conductionindirect.html ConductionIndirect>
% * <nusselt.html Nusselt>
% * <read.html Read>
% * <result.html Result>
% * <animation.html Animation>
% * <graph.html Graph>
%
%% Authors
%
% * Rafael Rangel (rrangel@cimne.upc.edu)
%
% International Center for Numerical Methods in Engineering
% (<https://www.cimne.com/ CIMNE>)
%
% <<logo_cimne.png>>
%
%% History
%
% * Version 1.0 - September, 2021
%
% Developed under the context of the
% <https://www.surrey.ac.uk/mathegram MATHEGRAM project>.
%
% <<logo_mathegram.png>>
%
%% Initialization
clc; clearvars; close all;
file = '';
addpath('algorithms',...
        'analysis',...
        'components',...
        'conditions',...
        'inlet_outlet',...
        'input_output',...
        'interactions',...
        'interactions/kinematics',...
        'interactions/force',...
        'interactions/rolling_resistance',...
        'interactions/heat_transfer',...
        'interactions/contact_area_fix');
Master().execute(file);