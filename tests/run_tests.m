%% Regression Tests
%
% This script file runs the selected test models and checks if the obtained
% results agree with the reference results.
%
% The desired test models files must be added to the string array _files_.
%
clc; clearvars; close all;
files = ["test_models\mech_bounce_straight.json",...
         "test_models\mech_bounce_oblique.json",...
         "test_models\mech_collision.json"...
         "test_models\mech_hopper.json"];

addpath(genpath(pwd));
addpath(genpath('..\src'));
Master().execute(files,0,1);