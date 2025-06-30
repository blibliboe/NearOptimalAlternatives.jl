export MGA_HSJ_update!

"""
  TODO
"""
function MGA_HSJ_update!(model::JuMP.Model, variables::AbstractArray{T,N}, weights::Vector{Float64}) where {T<:Union{VariableRef,AffExpr},N}
  # new objective function consist of the n variables in variables
  for (i, v) in enumerate(variables)
    if value(v) == 0
      weights[i] = 0
    else
      weights[i] = 1
    end
  end

  # update these variables based on their sign
  variables = [v * weights[i] for (i, v) in enumerate(variables)]

  # Update objective by adding the distance between variables and the previous optimal solution.
  @objective(model, Min, sum(variables))
end
