%% Regression Tests
%
% This script file runs the selected test models and checks if the obtained
% results agree with the reference results.
%
clc; clearvars; close all;
addpath(genpath(pwd));
addpath(genpath('..\src'));
Master().runTests(1);