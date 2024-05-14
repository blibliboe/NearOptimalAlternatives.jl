"""
Structure holding the solutions for the near-optimal alternatives.
"""
mutable struct AlternativeSolutions
  solutions::Vector{Dict{VariableRef, Float64}}
  objective_values::Vector{Float64}
end

"""
    update_solutions!(results::AlternativeSolutions, model::JuMP.Model)

Update the set of results `AlternativeSolutions` with the variable values obtained when solving the JuMP model `model`.
"""
function update_solutions!(results::AlternativeSolutions, model::JuMP.Model)
  if !is_solved_and_feasible(model)
    throw(ErrorException("JuMP model $model not solved when trying to read results."))
  end

  # Retrieve all variable values from JuMP model.
  solution = Dict{VariableRef, Float64}()
  for v in all_variables(model)
    solution[v] = value(v)
  end
  push!(results.solutions, solution)

  # Retrieve constraint for maximum difference to original objective and compute original objective value.
  original_objective = constraint_by_name(model, "original_objective")
  if isnothing(original_objective)
    throw(ErrorException("JuMP model $model has no constraint named `original_objective`"))
  end
  push!(results.objective_values, value(original_objective))
end
