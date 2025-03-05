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
  # get the nonzero variables
  rand_vars = filter(x -> randn() >= 0.0, all_variables(model))
  @info "Non-zero variables: " rand_vars

  # Fix the variables that are not to be changed.
  fix.(fixed_variables, value.(fixed_variables), force = true)

  # Objective maximising the distance between variables and the previous optimal solution.
  @objective(model, Min, sum(rand_vars))

  create_alternative_constraints!(model, optimality_gap)
end


"""
    MGA_Min_Max_alternatives!(
        model::JuMP.Model,
        metric::Distances.Metric
    )

Add a previously found solution to HSJ MGA problem. Used for iteratively finding multiple alternative solutions.
"""
function MGA_Min_Max_alternatives!(model::JuMP.Model)
  
  # Store all variables and solution values.
  rand_vars = filter(x -> randn() >= 0.0, all_variables(model))

  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Min, rand_vars)
end