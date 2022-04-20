%% Regression Tests
%
% This script file generates / updates the reference result files of the
% selected test models.
%
% ATTENTION: This action will overwrite existing reference results.
%
clc; clearvars; close all;
addpath(genpath(pwd));
addpath(genpath('..\src'));
Master().runTests(2);