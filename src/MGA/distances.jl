export MGA_Dist_update!

"""
  TODO
"""
function MGA_Dist_initial!(model::JuMP.Model, variables::AbstractArray{T,N}; metric::Distances.SemiMetric = Cityblock(),) where {T<:Union{VariableRef,AffExpr},N}
  # get the variable values
  vars_vec = [v for v in variables]
  solution = value.(vars_vec)

  # if metric isa Distances.Cityblock
  #   dist_expr = sum(abs.(vars_vec - solution))
  # elseif metric isa Distances.SqEuclidean
  #   dist_expr = sum((vars_vec - solution).^2)
  # else
  #   error("Metric not supported in this function")
  # end
  

  @objective(model, Max, Distances.evaluate(metric, vars_vec, solution))
  # @info "Updated objective " Distances.evaluate(metric, vars, solution)
end


"""
  TODO
"""
function MGA_Dist_update!(model::JuMP.Model, variables::AbstractArray{T,N}; metric::Distances.SemiMetric = Cityblock(),) where {T<:Union{VariableRef,AffExpr},N}
  # get the current objective function
  cumulative_distance = objective_function(model)

  # get the solution values
  vars_vec = [v for v in variables]
  solution = value.(vars_vec)


  # Reset objective sense to be able to update objective function.
  set_objective_sense(model, FEASIBILITY_SENSE)
  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Max, Distances.evaluate(metric, vars_vec, solution))
end

