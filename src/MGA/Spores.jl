export generate_MGA_SPORES!

"""
    result = generate_MGA_SPORES!(
      model::JuMP.Model,
      optimality_gap::Float64,
      n_alternatives::Int64;
      selected_variables::Vector{VariableRef} = []
    )

Generate `n_alternatives` solutions to `model` which are as distant from the optimum and each other using the SPORES method, but with a maximum `optimality_gap`, using optimisation.

# Arguments
- `model::JuMP.Model`: a solved JuMP model for which alternatives are generated.
- `optimality_gap::Float64`: the maximum percentage deviation (>=0) an alternative may have compared to the optimal solution.
- `n_alternatives`: the number of alternative solutions sought.
- `fixed_variables::Vector{VariableRef}=[]`: a subset of all variables of `model` that are not allowed to be changed when seeking for alternatives.
"""

function generate_MGA_SPORES!(
    model::JuMP.Model,
    optimality_gap::Float64,
    n_alternatives::Int64;
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
    weights = zeros(length(all_variables(model)))
  
    @info "Adding the original solution to the result."
    update_solutions!(result, model)
  
    @info "Creating model for generating alternatives."
    MGA_SPORES_initial!(model, optimality_gap, fixed_variables, weights)
    @info "Solving model."
    JuMP.optimize!(model)
    @info "Solution #1/$n_alternatives found." solution_summary(model)
    update_solutions!(result, model)
  
    # If n_solutions > 1, we repeat the solving process to generate multiple solutions.
    for i = 2:n_alternatives
      @info "Reconfiguring model for generating alternatives."
      MGA_SPORES_alternatives(model, weights)
      @info "Solving model."
      JuMP.optimize!(model)
      @info "Solution #$i/$n_alternatives found." solution_summary(model)
      update_solutions!(result, model)
    end
  
    return result
  end
  

"""
    MGA_SPORES_initial!(
        model::JuMP.Model,
        optimality_gap::Float64,
        [selected_variables::Vector{VariableRef}]
    )

Transform a JuMP model into a model solving its corresponding SPORES MGA

# Arguments
- `model::JuMP.Model`: a solved JuMP model for which alternatives are generated.
- `optimality_gap::Float64`: the maximum percentage deviation (>= 0) an alternative may have compared to the optimal solution.
- `fixed_variables::Vector{VariableRef}=[]`: a subset of all variables of `model` that are not allowed to be changed when seeking for alternatives.
"""
function MGA_SPORES_initial!(
  model::JuMP.Model,
  optimality_gap::Float64,
  fixed_variables::Vector{VariableRef},
  weights::Vector{Float64}
)
    optimal_value = objective_value(model)
    old_objective = objective_function(model)
    old_objective_sense = objective_sense(model)

    for (i, v) in enumerate(all_variables(model))
        weights[i] = value(v) / upper_bound(v)
    end
    # get the nonzero variables
    variables = [v * weights[i] for (i, v) in enumerate(all_variables(model))]  

    # Fix the variables that are not to be changed.
    fix.(fixed_variables, value.(fixed_variables), force = true)

    # Objective maximising the distance between variables and the previous optimal solution.
    @objective(model, Min, sum(variables))

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
    MGA_SPORES_alternatives(
        model::JuMP.Model,
        metric::Distances.Metric
    )

Add a previously found solution to SPORES MGA problem. Used for iteratively finding multiple alternative solutions.
"""
function MGA_SPORES_alternatives(model::JuMP.Model, weights::Vector{Float64})
  
  # Store all variables and solution values.
    for (i, v) in enumerate(all_variables(model))
        weights[i] = weights[i] + value(v) / upper_bound(v)
    end
    # get the nonzero variables
    variables = [v * weights[i] for (i, v) in enumerate(all_variables(model))]  

    @info "Adding the weights to the objective function." weights
    @info "The new objective function is: " variables

    # Update objective by adding the distance between variables and the previous optimal solution.
    @objective(model, Min, variables)
end
