export MGA_Dist_update!

"""
  TODO
"""
function MGA_Dist_initial!(model::JuMP.Model, variables::AbstractArray{T,N}; metric::Distances.SemiMetric = SqEuclidean(),) where {T<:Union{VariableRef,AffExpr},N}
  # get the variable values
  solution = value.(variables)
  vars = variables

  # # Reset objective sense to be able to update objective function.
  # set_objective_sense(model, FEASIBILITY_SENSE)
  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Max, Distances.evaluate(metric, vars, solution))
  @info "Updated objective " Distances.evaluate(metric, vars, solution)
end


"""
  TODO
"""
function MGA_Dist_update!(model::JuMP.Model, variables::AbstractArray{T,N}; metric::Distances.SemiMetric = SqEuclidean(),) where {T<:Union{VariableRef,AffExpr},N}
  # get the current objective function
  cumulative_distance = objective_function(model)

  # get the solution values
  solution = value.(variables)
  vars = variables


  # Reset objective sense to be able to update objective function.
  set_objective_sense(model, FEASIBILITY_SENSE)
  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Max, cumulative_distance + Distances.evaluate(metric, vars, solution))
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
