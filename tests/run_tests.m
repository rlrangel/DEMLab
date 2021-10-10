%% Regression Tests
%
% This script file runs the selected test models and checks if the obtained
% results agree with the base results.
%
% The desired test models files must be added to the string array _files_.
%
clc; clearvars; close all;
files = ["test_models\mech_bounce.json",...
         "test_models\mech_collision.json"];

addpath(genpath(pwd));
addpath(genpath('..\src'));
Master().execute(files,0,1);