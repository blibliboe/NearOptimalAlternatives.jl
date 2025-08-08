export MGA_EV_update!


"""
  TODO
"""
function MGA_EV_update!(model::JuMP.Model, variables::AbstractArray{T,N}, weights::Vector{Float64}) where {T<:Union{VariableRef,AffExpr},N}
  # new objective function consist of the n variables in variables
  for (i, v) in enumerate(variables)
    weights[i] = rand([1, 0, -1]) # for now assuming every variable has positive coefficient
  end

  while all(w -> w != -1, weights)
    for (i, v) in enumerate(variables)
      weights[i] = rand([1, 0, -1])
    end
  end

  # update these variables based on their sign
  variables = [v * weights[i] for (i, v) in enumerate(variables)]
  set_objective_sense(model, FEASIBILITY_SENSE)

  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Min, sum(variables))
end