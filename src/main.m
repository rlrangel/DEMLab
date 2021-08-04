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
% Code efficiency is not a priority and, therefore, only small problems
% should be simulated.
%
% For more information, visit the
% <https://gitlab.com/rafaelrangel/demlab GitLab repository>.

%% Instructions
%
% This is the main script file of the DEMLab program.
% To run a simulation, execute this script and select an appropriate input
% parameters file.
% 
% There are two ways to select the input parameters file:
%
% * Provide its path thorugh the string variable _file_ in the end of this
%   script.
% * Leave the string variable _file_ blank (file = '') and use the file
%   selection dialog box.

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
% * <Condition.html Condition>
% * <bbox.html BBox>
% * <sink.html Sink>
% * <interact.html Interact>
% * <binkinematics.html BinKinematics>
% * <contactforcen.html ContactForceN>
% * <contactforcet.html ContactForceT>
% * <contactconduction.html ContactConduction>
% * <read.html Read>
% * <result.html Result>
% * <animate.html Animate>
% * <graph.html Graph>

%% Authors
%
% * Rafael Rangel (rrangel@cimne.upc.edu)
%
% International Center for Numerical Methods in Engineering
% (<https://www.cimne.com/ CIMNE>)
%
% <<logo_cimne.png>>

%% History
%
% * Version 1.0 - August, 2021
%
% Developed under the context of the
% <https://www.surrey.ac.uk/mathegram MATHEGRAM project>.
%
% <<logo_mathegram.png>>

%% Initialization
clc; clearvars; close all;
addpath('algorithms',...
        'analysis',...
        'components',...
        'conditions',...
        'inlet_outlet',...
        'input_output',...
        'interactions',...
        'interactions/kinematics',...
        'interactions/force_models',...
        'interactions/heat_transfer_models');
file = 'C:\Users\rlr_5\gDrive\Work\Projects\DEMLab\DEMLab_git\models\mechanical_benchmarks\bouncing_ball_oblique\ProjectParameters.json';
Master().execute(file);