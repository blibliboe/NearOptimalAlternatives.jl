"""
    create_alternative_problem(
        model::JuMP.Model,
        optimality_gap::Float64,
        metric::Distances.Metric,
        [selected_variables::Vector{VariableRef}]
    )

Transform a JuMP model into a model solving its corresponding modelling-for-generating-alternatives problem.
"""
function create_alternative_problem!(
  model::JuMP.Model,
  optimality_gap::Float64,
  metric::Distances.SemiMetric,
  selected_variables::Vector{VariableRef},
)
  optimal_value = objective_value(model)
  old_objective = objective_function(model)
  old_objective_sense = objective_sense(model)

  # Store all variables and solution values.
  variables = VariableRef[]
  solution = Float64[]
  for v in all_variables(model)
    push!(variables, v)
    push!(solution, value(v))
  end

  # Fix the variables that are not to be changed (not in selected_variables).
  for i in eachindex(variables)
    if !isempty(selected_variables) && variables[i] ∉ selected_variables
      fix(variables[i], solution[i], force = true)
    end
  end

  # Objective maximising the distance between variables and the previous optimal solution.
  @objective(model, Max, Distances.evaluate(metric, variables, solution))

  # Constraint ensuring maximum difference in objective value to optimal solution.
  if old_objective_sense == MAX_SENSE
    c = @constraint(model, original_objective, old_objective ≥ optimal_value * (1 - optimality_gap))
    # set_name(c, "original_objective")
  else
    c = @constraint(model, original_objective, old_objective ≤ optimal_value * (1 + optimality_gap))
    # set_name(c, "original_objective")
  end
end

"""
    add_solution!(
        model::JuMP.Model,
        metric::Distances.Metric
    )

Adds a previously found solution to a modelling-for-generating-alternatives problem. Used for iteratively finding multiple alternative solutions.
"""
function add_solution!(model::JuMP.Model, metric::Distances.SemiMetric)
  old_objective = objective_function(model)

  # Store all variables and solution values.
  variables = VariableRef[]
  solution = Float64[]
  for v in all_variables(model)
    push!(variables, v)
    push!(solution, value(v))
  end

  # Reset objective sense to be able to update objective function.
  set_objective_sense(model, FEASIBILITY_SENSE)
  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Max, old_objective + Distances.evaluate(metric, variables, solution))
end
