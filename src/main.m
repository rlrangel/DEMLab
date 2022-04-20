%% DEMLab - Discrete Element Method Laboratory
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
% Multiple files can be selected to run simulations sequentially,
% as long as they are located in the same folder.
%
% A sub-folder with the problem name plus the suffix "_out" is created to
% receive the output files with the simulation results.
%
%% OOP classes
%
% This program adopts an Object Oriented Programming (OOP) paradigm.
% The following OOP super-classes are implemented:
%
% *Analysis*:
%
% * <Master.html Master>
% * <Driver.html Driver>
%
% *Algorithms*:
%
% * <Scheme.html Scheme>
% * <Search.html Search>
%
% *Components*:
%
% * <Particle.html Particle>
% * <Wall.html Wall>
% * <Material.html Material>
% * <ModelPart.html ModelPart>
%
% *Interaction Models*:
%
% * <Interact.html Interact>
% * <BinKinematics.html BinKinematics>
% * <ContactForceN.html ContactForceN>
% * <ContactForceT.html ContactForceT>
% * <RollResist.html RollResist>
% * <ConductionDirect.html ConductionDirect>
% * <ConductionIndirect.html ConductionIndirect>
% * <Nusselt.html Nusselt>
% * <AreaCorrect.html AreaCorrect>
%
% *Conditions*:
%
% * <Condition.html Condition>
%
% *Inlet/Outlet*:
%
% * <BBox.html BBox>
% * <Sink.html Sink>
%
% *Input/Output*:
%
% * <Read.html Read>
% * <Print.html Print>
% * <Graph.html Graph>
% * <Animation.html Animation>
% * <Result.html Result>
%
%% Initialization
clc; clearvars; close all;
addpath(genpath(pwd));
Master().execute();