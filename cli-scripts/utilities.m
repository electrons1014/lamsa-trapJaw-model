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


%% helper function to create components from run parameters
function components = initializeComponents(component_config, run_params)
    component_names = {component_config.name};
    components = cell(1,length(component_config));
    for component = 1:length(component_config)
        component_params = struct2cell(run_params{component});
        components{component} = feval(component_names{component}, component_params{:});
    end
end


%% helper function to run LaMSA and MDA simulations + report values for given components
function [lamsa_met, mda_met] = simulate(components, mets)

    [lamsa_sol, lamsa_transitions] = solve_lamsa(components{4}, components{5}, components{1}, components{2}, components{3});
    lamsa_met = get_metrics(lamsa_sol, lamsa_transitions, load, mets);

    [mda_sol, mda_transitions] = solve_direct_actuation(components{4}, components{1});
    mda_met = get_metrics(mda_sol, mda_transitions, load, mets);

end