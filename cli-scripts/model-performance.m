addpath(genpath(fullfile(pwd,'..')));
RUN_PATH = input('path to simulation run directory: ', 's');
COMPONENTS_PATH = fullfile(run_directory, 'components-config.json');
METRICS_PATH = fullfile(run_directory, 'metrics-config.json');

component_order = ["load", "latch", "spring", "load_motor", "latch_motor"];
component_config = jsondecode(fileread(COMPONENTS_PATH));
metrics = jsondecode(fileread(METRICS_PATH));

if length(component_config) ~= length(component_order)
    error('parameters.json must describe all 5 components');
end

if ~isequal({component_order{:}}, {component_config.component})
    error('parameters.json must order components as load, latch, spring, load motor, latch motor');
end


iterable_params = findIterable(component_config);
num_iterable = size(iterable_params, 1);
num_runs = 1;
for param = 1:num_iterable
    num_runs = num_runs .* size(iterable_params{param, 4}, 2);
end

component_names = {component_config.name};

for run = 1:num_runs
    run_params = setRunParams(component_config, iterable_params);

    componenets = cell(1,5);
    for component = 1:length(component_config)
        component_params = struct2cell(run_params{component});
        components{component} = feval(component_names{component}, component_params{:});
    end

    [lamsa_metrics, mda_metrics] = simulate(components, metrics);

    for param = 1:num_iterable
        if iterable_params{param, 3} < size(iterable_params{param, 4}, 2)
            iterable_params{param, 3} = iterable_params{param, 3} + 1;
            break;
        end
        iterable_params{param, 3} = 1;
    end
end


%% helper function to detect iterable parameters
function iterable = findIterable(config)
    iterable = cell(0,0);
    params = {config.parameters};

    for component = 1:5
        component_params = fields(params{component});
        for i = 1:length(component_params)
            val = getfield(params{component}, component_params{i});
            if length(val) == 3
                iterable = [iterable; {component, component_params{i}, 1, linspace(val(1), val(2), val(3))}];
            elseif length(val) ~= 1
                error('inputted parameter has wrong length. must be scalar or length 3 array');
            end
        end
    end
end


%% helper function to set run parameters
function run = setRunParams(config, iterable)
    run = {config.parameters};
    num_iterable = size(iterable, 1);
    for param = 1:num_iterable
        run{iterable{param, 1}} = setfield(run{iterable{param, 1}}, iterable{param, 2}, iterable{param, 4}(1));
    end
end


%% helper function to run LaMSA and MDA simulations + report values for given components
function [lamsa_met, mda_met] = simulate(components, mets)

    load = components{1};
    latch = components{2};
    spring = components{3};
    load_motor = componenets{4};
    latch_motor = componenets{5};

    [lamsa_sol, lamsa_transitions] = solve_lamsa(load_motor, latch_motor, load, latch, spring);
    lamsa_met = get_metrics(lamsa_sol, lamsa_transitions, load, mets);

    [mda_sol, mda_transitions] = solve_direct_actuation(load_motor, load);
    mda_met = get_metrics(mda_sol, mda_transitions, load, mets);