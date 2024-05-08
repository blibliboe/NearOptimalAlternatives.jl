export generate_alternatives

"""
    result = generate_alternatives!(
      model::JuMP.Model,
      optimality_gap::Float64,
      n_alternatives::Int64;
      metric::Distances.Metric = SqEuclidean(),
      selected_variables::Vector{VariableRef} = []
    )

Generate `n_alternatives` solutions to `model` which are as distant from the optimum and each other, but with a maximum `optimality_gap`.

# Arguments
- `model::JuMP.Model`: a solved JuMP model for which alternatives are generated.
- `optimality_gap::Float64`: the maximum percentage deviation (∈ [0,1]) an alternative may have compared to the optimal solution.
- `n_alternatives`: the number of alternative solutions sought.
- `metric::Distances.Metric=SqEuclidean()`: the metric used to maximise the difference between alternatives and the optimal solution.
- `selected_variables::Vector{VariableRef}=[]`: a subset of all variables of `model` that are allowed to be changed when seeking for alternatives (when left empty, all variables can change).
"""
function generate_alternatives!(
  model::JuMP.Model,
  optimality_gap::Float64,
  n_alternatives::Int64;
  metric::Distances.SemiMetric = SqEuclidean(),
  selected_variables::Vector{VariableRef} = VariableRef[],
)
  if !is_solved_and_feasible(model)
    throw(ArgumentError("JuMP model has not been solved."))
  elseif optimality_gap < 0 || optimality_gap > 1
    throw(ArgumentError("Optimality gap (= $optimality_gap) is not in [0,1]."))
  elseif n_alternatives < 1
    throw(ArgumentError("Number of alternatives (= $n_alternatives) should be at least 1."))
  end

  result = AlternativeSolutions([], [])

  @info "Creating model for generating alternatives."
  create_alternative_problem!(model, optimality_gap, metric, selected_variables)
  @info "Solving model."
  optimize!(model)
  @info "Solution #1/$n_alternatives found." solution_summary(model)
  update_solutions!(result, model)

  # If n_solutions > 1, we repeat the solving process to generate multiple solutions.
  for i = 2:n_alternatives
    @info "Reconfiguring model for generating alternatives."
    add_solution!(model, metric)
    @info "Solving model."
    optimize!(model)
    @info "Solution #$i/$n_alternatives found." solution_summary(model)
    update_solutions!(result, model)
  end

  return result
end
