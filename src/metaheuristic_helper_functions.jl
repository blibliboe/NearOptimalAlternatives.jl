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
    objective = extract_objective(
        objective::JuMP.AffExpr,
        x::Vector{Float64},
        index_map::Dict{Int64, Int64},
        fixed_variables::Dict{MOI.VariableIndex, Float64}
    )

Convert the objective from a MathOptInterface function into a julia function of x. Supports only linear single-objective functions.

# Arguments
- `objective::JuMP.AffExpr`: the objective function to transform into a julia function.
- `x::Vector{Float64}`: a vector representing an individual in the metaheuristic population.
- `index_map::Dict{Int64, Int64}`: a dictionary mapping indices in the MathOptInterface model to indices of `x`.
- `fixed_variables::Dict{MOI.VariableIndex, Float64}: a dictionary containing the values of the fixed variables.`
"""
function extract_objective(
  objective::JuMP.AffExpr,
  x::Vector{Float64},
  index_map::Dict{Int64, Int64},
  fixed_variables::Dict{MOI.VariableIndex, Float64},
)
  result = 0
  # Add the constant in the objective function.
  result += objective.constant
  # Add all terms in the objective function with variables iteratively.
  for (var, coef) in objective.terms
    # If variable in `index_map`, add corresponding value to the result. Else, the variable is fixed and add the original resulting variable.
    if haskey(index_map, var.index.value)
      result += coef * x[index_map[var.index.value]]
    else
      result += coef * fixed_variables[var.index]
    end
  end
  return result
end

"""
    objective = extract_objective(
        objective::JuMP.QuadExpr,
        x::Vector{Float64},
        index_map::Dict{Int64, Int64},
        fixed_variables::Dict{MOI.VariableIndex, Float64}
    )

Convert the objective from a MathOptInterface function into a julia function of x. Supports Quadratic Expression

# Arguments
- `objective::JuMP.QuadExpr`: the objective function to transform into a julia function.
- `x::Vector{Float64}`: a vector representing an individual in the metaheuristic population.
- `index_map::Dict{Int64, Int64}`: a dictionary mapping indices in the MathOptInterface model to indices of `x`.
- `fixed_variables::Dict{MOI.VariableIndex, Float64}: a dictionary containing the values of the fixed variables.`
"""
function extract_objective(
  objective::JuMP.QuadExpr,
  x::Vector{Float64},
  index_map::Dict{Int64, Int64},
  fixed_variables::Dict{MOI.VariableIndex, Float64},
)
    # Add linear part of the objective function.
    
    result = extract_objective(objective.aff, x, index_map, fixed_variables)
    # Add all terms in the objective function with variables iteratively.
    for (vars, coef) in objective.terms
        # If variable in `index_map`, add corresponding value to the result. Else, the variable is fixed and add the original resulting variable.
        a = vars.a 
        b = vars.b
        if haskey(index_map, a.index.value) && haskey(index_map, b.index.value)
            result += coef * x[index_map[a.index.value]] * x[index_map[b.index.value]]
        elseif haskey(index_map, a.index.value)
            result += coef * x[index_map[a.index.value]] * fixed_variables[b]
        elseif haskey(index_map, b.index.value)
            result += coef * fixed_variables[a] * x[index_map[b.index.value]]
        else
            result += coef * fixed_variables[a] * fixed_variables[b]
        end
    end
    return result
end

"""
    constraint = extract_constraint(
        constraint::MOI.ConstraintFunction,
        x::Vector{Float64},
        index_map::Dict{Int64, Int64},
        fixed_variables::Dict{MOI.VariableIndex, Float64}
    )

Convert a constraint from a MathOptInterface function into a julia function of x. Supports only ScalarAffineFunction and VariableIndex constraints.

# Arguments
- `constraint::MOI.ConstraintFunction`: constraint transform into a julia function.
- `x::Vector{Float64}`: a vector representing an individual in the metaheuristic population.
- `index_map::Dict{Int64, Int64}`: a dictionary mapping indices in the MathOptInterface model to indices of `x`.
- `fixed_variables::Dict{MOI.VariableIndex, Float64}: a dictionary containing the values of the fixed variables.`
"""
function extract_constraint(
  constraint::MOI.ScalarAffineFunction,
  x::Vector{Float64},
  index_map::Dict{Int64, Int64},
  fixed_variables::Dict{MOI.VariableIndex, Float64},
)
  result = 0
  for t in constraint.terms
    if haskey(index_map, t.variable.value)
      result += t.coefficient * x[index_map[t.variable.value]]
    else
      result += t.coefficient * fixed_variables[t.variable]
    end
  end
  return result
end

"""
    bounds = extract_bounds(
        model::JuMP.Model,
        index_map::Dict{Int64, Int64}
    )

Transform the bounds from a JuMP Model into a matrix of bounds readable by Metaheuristics.jl.

# Arguments
- `model::JuMP.Model`: solved JuMP model of the original lp problem.
- `index_map::Dict{Int64, Int64}`: dictionary mapping indices in the JuMP/MathOptInterface model to indices of `x`.
"""
function extract_bounds(model::JuMP.Model, index_map::Dict{Int64, Int64})
  # Initialise bound matrix with all variables between -Inf and Inf.
  n_variables = length(index_map)
  bounds = zeros(Float64, (2, n_variables))
  for i = 1:n_variables
    bounds[1, i] = -Inf
    bounds[2, i] = Inf
  end

  # Obtain all constraints from the model.
  constraints = all_constraints(model, include_variable_in_set_constraints = true)

  for c in constraints
    c_fun = MOI.get(model, MOI.ConstraintFunction(), c)
    # Check if constraint is a bound. In that case add upper and lower bounds depending on type of constraint.
    if isa(c_fun, MOI.VariableIndex) && haskey(index_map, c_fun.value)
      c_set = MOI.get(model, MOI.ConstraintSet(), c)
      if isa(c_set, MOI.LessThan)
        bounds[2, index_map[c_fun.value]] = MOI.constant(c_set)
      elseif isa(c_set, MOI.GreaterThan)
        bounds[1, index_map[c_fun.value]] = MOI.constant(c_set)
      elseif isa(c_set, MOI.EqualTo)
        bounds[1, index_map[c_fun.value]] = MOI.constant(c_set)
        bounds[2, index_map[c_fun.value]] = MOI.constant(c_set)

      elseif isa(c_set, MOI.Interval)
        bounds[1, index_map[c_fun.value]] = c_set.lower
        bounds[2, index_map[c_fun.value]] = c_set.upper
      end
    end
  end

  return bounds
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