"""
    create_alternative_constraints!(
        model::JuMP.Model,
        optimality_gap::Float64,
    )

Adds original objective function as constraint to the model

# Arguments
- `model::JuMP.Model`: a solved JuMP model for which alternatives are generated.
- `optimality_gap::Float64`: the maximum percentage deviation (>= 0) an alternative may have compared to the optimal solution.
"""
function create_alternative_constraints!(
  model::JuMP.Model,
  optimality_gap::Float64,
)
  optimal_value = objective_value(model)
  old_objective = objective_function(model)
  old_objective_sense = objective_sense(model)
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