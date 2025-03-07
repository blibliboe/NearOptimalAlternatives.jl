export generate_MGA_distances!

"""
    result = generate_MGA_distances!(
      model::JuMP.Model,
      optimality_gap::Float64,
      n_alternatives::Int64;
      metric::Distances.Metric = SqEuclidean(),
      selected_variables::Vector{VariableRef} = []
    )

Generate `n_alternatives` solutions to `model` which are as distant from the optimum and each other using a distance metric, but with a maximum `optimality_gap`, using optimisation.

# Arguments
- `model::JuMP.Model`: a solved JuMP model for which alternatives are generated.
- `optimality_gap::Float64`: the maximum percentage deviation (>=0) an alternative may have compared to the optimal solution.
- `n_alternatives`: the number of alternative solutions sought.
- `metric::Distances.Metric=SqEuclidean()`: the metric used to maximise the difference between alternatives and the optimal solution.
- `fixed_variables::Vector{VariableRef}=[]`: a subset of all variables of `model` that are not allowed to be changed when seeking for alternatives.
"""
function generate_MGA_distances!(
  model::JuMP.Model,
  optimality_gap::Float64,
  n_alternatives::Int64;
  metric::Distances.SemiMetric = SqEuclidean(),
  fixed_variables::Vector{VariableRef} = VariableRef[],
)
  if !is_solved_and_feasible(model)
    throw(ArgumentError("JuMP model has not been solved."))
  elseif optimality_gap < 0
    throw(ArgumentError("Optimality gap (= $optimality_gap) should be at least 0."))
  elseif n_alternatives < 1
    throw(ArgumentError("Number of alternatives (= $n_alternatives) should be at least 1."))
  end

  result = AlternativeSolutions([], [])

  @info "Adding the original solution to the result."
  update_solutions!(result, model)

  @info "Creating model for generating alternatives."
  MGA_distances_initial!(model, optimality_gap, metric, fixed_variables)
  @info "Solving model."
  JuMP.optimize!(model)
  @info "Solution #1/$n_alternatives found." solution_summary(model)
  update_solutions!(result, model)

  # If n_solutions > 1, we repeat the solving process to generate multiple solutions.
  for i = 2:n_alternatives
    @info "Reconfiguring model for generating alternatives."
    MGA_distance_alternatives!(model, metric)
    @info "Solving model."
    JuMP.optimize!(model)
    @info "Solution #$i/$n_alternatives found." solution_summary(model)
    update_solutions!(result, model)
  end

  return result
end

"""
    MGA_distances_initial!(
        model::JuMP.Model,
        optimality_gap::Float64,
        metric::Distances.Metric,
        [selected_variables::Vector{VariableRef}]
    )

Transform a JuMP model into a MGA model that maximizes the given distance between the optimal solution and alternative solutions

# Arguments
- `model::JuMP.Model`: a solved JuMP model for which alternatives are generated.
- `optimality_gap::Float64`: the maximum percentage deviation (>= 0) an alternative may have compared to the optimal solution.
- `metric::Distances.Metric=SqEuclidean()`: the metric used to maximise the difference between alternatives and the optimal solution.
- `fixed_variables::Vector{VariableRef}=[]`: a subset of all variables of `model` that are not allowed to be changed when seeking for alternatives.
"""

function MGA_distances_initial!(
    model::JuMP.Model,
    optimality_gap::Float64,
    metric::Distances.SemiMetric,
    fixed_variables::Vector{VariableRef},
  )
        
    optimal_value = objective_value(model)
    old_objective = objective_function(model)
    old_objective_sense = objective_sense(model)
  
    # Store all variables and solution values.
    variables, solution = extract_variables(model)
  
    # Fix the variables that are not to be changed.
    fix.(fixed_variables, value.(fixed_variables), force = true)
  
    # Objective maximising the distance between variables and the previous optimal solution.
    @objective(model, Max, Distances.evaluate(metric, variables, solution))


    # Constraint ensuring maximum difference in objective value to optimal solution. The sign of `optimal_value` is used to ensure that a negative `optimal_value` does not lead to an infeasible bound requiring a better than optimal solution.
    if old_objective_sense == MAX_SENSE
    @constraint(
        model,
        original_objective,
        old_objective ≥ optimal_value * (1 - optimality_gap * sign(optimal_value))
    )
    else
    @constraint(
        model,
        original_objective,
        old_objective ≤ optimal_value * (1 + optimality_gap * sign(optimal_value))
    )
    end
  
end

"""
    MGA_distance_alternatives!(
        model::JuMP.Model,
        metric::Distances.Metric
    )

Update the model to find the next alternative solution, in case of distance 
"""
function MGA_distance_alternatives!(model::JuMP.Model, metric::Distances.SemiMetric)
  cumulative_distance = objective_function(model)

  # Store all variables and solution values.
  variables, solution = extract_variables(model)

  # Reset objective sense to be able to update objective function.
  set_objective_sense(model, FEASIBILITY_SENSE)
  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Max, cumulative_distance + Distances.evaluate(metric, variables, solution))
end

"""
    extract_variables(model::JuMP.Model)

Retrieve the variables and their solution values from a JuMP `model` to be used for finding the distance.
"""
function extract_variables(model::JuMP.Model)
  variables = all_variables(model)
  solution = value.(variables)
  return variables, solution
end
