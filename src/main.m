%% DEMLab - Discrete Element Method Laboratory
%
%% Description
%
%% OOP classes
%
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
file = 'C:\Users\rlr_5\gDrive\Work\Projects\DEMLab\DEMLab_git\models\YIC2021\ProjectParameters.json';
Master().runSimulation(file);