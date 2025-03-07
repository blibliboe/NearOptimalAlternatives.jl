export generate_MGA_Min_Max!

"""
    result = generate_MGA_Min_Max!(
      model::JuMP.Model,
      optimality_gap::Float64,
      n_alternatives::Int64;
      selected_variables::Vector{VariableRef} = []
    )

Generate `n_alternatives` solutions to `model` which are as distant from the optimum and each other using the Min/Max variable method, but with a maximum `optimality_gap`, using optimisation.

# Arguments
- `model::JuMP.Model`: a solved JuMP model for which alternatives are generated.
- `optimality_gap::Float64`: the maximum percentage deviation (>=0) an alternative may have compared to the optimal solution.
- `n_alternatives`: the number of alternative solutions sought.
- `fixed_variables::Vector{VariableRef}=[]`: a subset of all variables of `model` that are not allowed to be changed when seeking for alternatives.
"""

function generate_MGA_Min_Max!(
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
  
    @info "Adding the original solution to the result."
    update_solutions!(result, model)
  
    @info "Creating model for generating alternatives."
    MGA_Min_Max_initial!(model, optimality_gap, fixed_variables)
    @info "Solving model."
    JuMP.optimize!(model)
    @info "Solution #1/$n_alternatives found." solution_summary(model)
    update_solutions!(result, model)
  
    # If n_solutions > 1, we repeat the solving process to generate multiple solutions.
    for i = 2:n_alternatives
      @info "Reconfiguring model for generating alternatives."
      MGA_Min_Max_alternatives!(model)
      @info "Solving model."
      JuMP.optimize!(model)
      @info "Solution #$i/$n_alternatives found." solution_summary(model)
      update_solutions!(result, model)
    end
  
    return result
  end

"""
    MGA_Min_Max!(
        model::JuMP.Model,
        optimality_gap::Float64,
        [selected_variables::Vector{VariableRef}]
    )

Transform a JuMP model into a model solving its corresponding Min/Max variable MGA

# Arguments
- `model::JuMP.Model`: a solved JuMP model for which alternatives are generated.
- `optimality_gap::Float64`: the maximum percentage deviation (>= 0) an alternative may have compared to the optimal solution.
- `fixed_variables::Vector{VariableRef}=[]`: a subset of all variables of `model` that are not allowed to be changed when seeking for alternatives.
"""
function MGA_Min_Max_initial!(
  model::JuMP.Model,
  optimality_gap::Float64,
  fixed_variables::Vector{VariableRef},
)
    optimal_value = objective_value(model)
    old_objective = objective_function(model)
    old_objective_sense = objective_sense(model)
    # get random variables to minimize and maximize where there is no overlap between minimizing and maximizing
    n = length(all_variables(model))
    random_array = rand([-1, 0, 1], n)

    variables = [v * random_array[i] for (i, v) in enumerate(all_variables(model))]  

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
    MGA_Min_Max_alternatives!(
        model::JuMP.Model,
        metric::Distances.Metric
    )

Add a previously found solution to Min/Max Variable problem. Used for iteratively finding multiple alternative solutions.
"""
function MGA_Min_Max_alternatives!(model::JuMP.Model)
  
    n = length(all_variables(model))
    random_array = rand([-1, 0, 1], n)

    variables = [v * random_array[i] for (i, v) in enumerate(all_variables(model))]

    # Update objective by adding the distance between variables and the previous optimal solution.
    @objective(model, Min, variables)
end