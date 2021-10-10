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
%   of this script (e.g. file = "C:\...\ProjectParameters.json").
% * Leave the string variable _file_ blank (file = "") and use the
%   selection dialog that appears when running this script.
%
% In both cases, multiple files can be selected to run simulations
% sequentially, as long as they are located in the same folder.
%
% A folder with the problem name plus the suffix "_out" is created to
% receive the output files.
%
%% OOP classes
%
% This program adopts an Object Oriented Programming (OOP) paradigm.
% The following OOP super-classes are implemented:
%
% * <animation.html Animation>
% * <areacorrect.html AreaCorrect>
% * <bbox.html BBox>
% * <binkinematics.html BinKinematics>
% * <condition.html Condition>
% * <conductiondirect.html ConductionDirect>
% * <conductionindirect.html ConductionIndirect>
% * <contactforcen.html ContactForceN>
% * <contactforcet.html ContactForceT>
% * <driver.html Driver>
% * <graph.html Graph>
% * <interact.html Interact>
% * <master.html Master>
% * <material.html Material>
% * <modelpart.html ModelPart>
% * <nusselt.html Nusselt>
% * <particle.html Particle>
% * <print.html Print>
% * <read.html Read>
% * <result.html Result>
% * <rollresist.html RollResist>
% * <scheme.html Scheme>
% * <search.html Search>
% * <sink.html Sink>
% * <wall.html Wall>
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
files = "";
addpath(genpath(pwd));
Master().execute(files,1);
