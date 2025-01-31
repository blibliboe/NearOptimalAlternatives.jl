"""
    Structure representing a problem that can be solved by Metaheuristics.jl and the algorithm to solve it.
"""
mutable struct MetaheuristicProblem
  objective::Function
  bounds::Matrix{Float64}
  algorithm::Metaheuristics.Algorithm
end

"""
    add_solution!(
        problem::MetaheuristicProblem,
        result::Metaheuristics.State,
        metric::Distances.SemiMetric
    )

Modify a Metaheuristic problem representing the alternative generating problem for the original LP using a newly found alternative solution. This function can be used when one wants to iteratively run a metaheuristic to find alternative solutions one by one.
NOTE: running metaheuristics one by one seems innefficient so should not be used as much

# Arguments:
- `problem::MetaheuristicProblem`: problem to be modified by adding a solution.
- `result::Metaheuristics.State`: result containing the optimal solution to add to the objective function.
- `metric::Distances.SemiMetric`: metric used to evaluate distance between alternatives.
"""
function add_solution!(
  problem::MetaheuristicProblem,
  result::Metaheuristics.State,
  metric::Distances.SemiMetric,
)
  # Create new objective function using old objective function.
  objective = problem.objective
  solution = minimizer(result)
  function f(x)
    f_old, gx, hx = objective(x)
    fx = [f_old[1] - Distances.evaluate(metric, solution, x)]
    return fx, gx, hx
  end
  problem.objective = f
end

"""
    result = run_alternative_generating_problem!(
        problem::MetaheuristicProblem
    )

Optimise the `problem` using the specified metaheuristic algorithm and return the result.
"""
function run_alternative_generating_problem!(problem::MetaheuristicProblem)
  result = Metaheuristics.optimize(problem.objective, problem.bounds, problem.algorithm)
  return result
end