%% DEMLab - Discrete Element Method Laboratory
%
% <<../images/logos/logo_demlab.png>>
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
% * Provide its complete path thorugh the string variable _files_ in the
%   end of this script (e.g. files = "C:\...\ProjectParameters.json").
% * Leave the string variable _files_ blank (files = "") and use the
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
% * <Animation.html Animation>
% * <AreaCorrect.html AreaCorrect>
% * <BBox.html BBox>
% * <BinKinematics.html BinKinematics>
% * <Condition.html Condition>
% * <ConductionDirect.html ConductionDirect>
% * <ConductionIndirect.html ConductionIndirect>
% * <ContactForceN.html ContactForceN>
% * <ContactForceT.html ContactForceT>
% * <Driver.html Driver>
% * <Graph.html Graph>
% * <Interact.html Interact>
% * <Master.html Master>
% * <Material.html Material>
% * <ModelPart.html ModelPart>
% * <Nusselt.html Nusselt>
% * <Particle.html Particle>
% * <Print.html Print>
% * <Read.html Read>
% * <Result.html Result>
% * <RollResist.html RollResist>
% * <Scheme.html Scheme>
% * <Search.html Search>
% * <Sink.html Sink>
% * <Wall.html Wall>
%
%% Initialization
clc; clearvars; close all;
files = "";
addpath(genpath(pwd));
Master().execute(files);