%% set path information
addpath(genpath(fullfile(pwd,'..')));
RUN_PATH = input('path to simulation run directory: ', 's');
PARAMS_PATH = fullfile(run_directory, 'parameters.json');

%% parse parameters from parameters.json
component_order = ["load", "latch", "spring", "load_motor", "latch_motor"];
component_config = jsondecode(fileread(PARAMS_PATH));

% validate parameters.json (incomplete!)
if length(component_config) ~= length(component_order)
    error('parameters.json must describe all 5 components');

if !isequal({component_order{:}}, {component_config.component})
    error('parameters.json must order components as load, latch, spring, load motor, latch motor');

% identify iterable parameters

iterable_params = findIterable(component_config);




components = cell(1,5);


% initialize components
load = feval(params(1).name, struct2cell(params(1).parameters){:});
latch = feval(params(2).name, struct2cell(params(2).parameters){:});
spring = feval(params(3).name, struct2cell(params(3).parameters){:});
load_motor = feval(params(4).name, struct2cell(params(4).parameters){:});
latch_motor = feval(params(5).name, struct2cell(params(5).parameters){:});


%% helper function to detect iterable parameters
function iterable = findIterable(config)
    iteratable = cell(0,0);
    params = {config.parameters};

    for component = 1:5
        component_params = fields(params{component});
        for i = 1:length(component_params)
            val = getfield(params{component}, component_params{i});
            if length(val) == 3
                iterable = [iterable; {component, component_params{i}, 0, linspace(val(1), val(2), val(3))}];
            elseif length(val) != 1
                error('inputted parameter has wrong length. must be scalar or length 3 array');
            end
        end
    end
end


%% helper function to run LaMSA and MDA simulations + report values for given components
function [lamsa_metrics, mda_metrics] = simulate(components)

    load = components{1};
    latch = components{2};
    spring = components{3};
    load_motor = componenets{4};
    latch_motor = componenets{5};

    metrics = {
        'y_latch',
        't_unlatch',
        'theta_unlatch',
        'omega_unlatch',
        'v_unlatch',
        'KE_unlatch',
        't_takeoff',
        'theta_takeoff',
        'omega_takeoff',
        'v_takeoff',
        'KE_takeoff',
        't_close'
        };

    [lamsa_sol, lamsa_transitions] = solve_lamsa(load_motor, latch_motor, load, latch, spring);
    lamsa_metrics = get_metrics(lamsa_sol, lamsa_transitions, load, metrics);

    [mda_sol, mda_transitions] = solve_direct_actuation(load_motor, load);
    mda_metrics = get_metrics(mda_sol, mda_transitions, load, metrics);