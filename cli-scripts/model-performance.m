%% set path information
addpath(genpath(fullfile(pwd,'..')));
run_directory = input('path to run directory: ', 's');
parameters = fullfile(run_directory, 'parameters.json');

%% parse parameters from parameters.json and initialize componenets